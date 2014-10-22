//
//  VJBMessage.m
//  JBMessage
//
//  Created by Josip Bernat on 25/03/14.
//  Copyright (c) 2014 Josip-Bernat. All rights reserved.
//

#import "JBMessage.h"
#import "AFHTTPRequestOperationManager.h"
#import "JBMessage+NSURLConnection.h"

JBHTTPMethod const JBHTTPMethodGET      = @"GET";
JBHTTPMethod const JBHTTPMethodPOST     = @"POST";
JBHTTPMethod const JBHTTPMethodPUT      = @"PUT";
JBHTTPMethod const JBHTTPMethodDELETE   = @"DELETE";

NSString * const JBMessageReachabilityStatusChangedNotification = @"JBMessageReachabilityStatusChangedNotification";
NSString * const JBMessageReachabilityStatusKey                 = @"JBMessageReachabilityStatusKey";

static dispatch_queue_t jb_message_completion_callback_queue() {
    
    static dispatch_queue_t completion_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        completion_queue = dispatch_queue_create("com.jbmessage.completion.queue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return completion_queue;
}

@interface JBMessage () {

    BOOL _isCancelled;
    BOOL _isFinished;
    BOOL _isExecuting;

    id _willResignObserver;
}

@property (nonatomic, strong) AFHTTPRequestOperation *operation;

#pragma mark - Shared Queue
+ (NSOperationQueue *)sharedQueue;

#pragma mark - Shared Instance
+ (instancetype)sharedInstance;

@end

@implementation JBMessage

#pragma mark - Memory Management

- (void) dealloc {
    
    _responseBlock = nil;
    _uploadBlock = nil;
    
    if (_willResignObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_willResignObserver];
    }
}

#pragma mark - Shared Queue

+ (NSOperationQueue *)sharedQueue {
    
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        [queue setName:@"com.jbmessage.shared_queue"];
    });
    
    return queue;
}

#pragma mark - Shared Instance

+ (void)load {
    [self sharedInstance];
}

+ (instancetype)sharedInstance {
    
    static JBMessage *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance updateReachability];
    });
    return instance;
}

- (void)updateReachability {
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:JBMessageReachabilityStatusChangedNotification
                                                            object:nil
                                                          userInfo:@{JBMessageReachabilityStatusKey: @(status)}];
    }];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

#pragma mark - URL Registration

static NSString *baseUrlString = nil;

+ (void)registerBaseUrl:(NSString *)baseUrl {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseUrlString = baseUrl;
    });
}
+ (NSString *)registratedBaseUrl {
    return baseUrlString;
}

+ (void)requsterMaxNumberOfConcurrentMessages:(NSUInteger)maxConcurrentMessages {

    [[JBMessage sharedQueue] setMaxConcurrentOperationCount:maxConcurrentMessages];
}

#pragma mark - Reachability

+ (JBMessageReachabilityStatus)reachabilityStatus {
    return (JBMessageReachabilityStatus) [[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus];
}

+ (BOOL)isInternetReachable {
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

#pragma mark - Initialization

+ (instancetype)messageWithParameters:(NSDictionary *) parameters
                        responseBlock:(JBResponseBlock) responseBlock {
    
    JBMessage *message = [[self alloc] initWithParameters:parameters
                                            responseBlock:responseBlock];
    return message;
}

+ (instancetype)messageWithURL:(NSURL *)URL
                    parameters:(NSDictionary *)parameters
                 responseBlock:(JBResponseBlock) responseBlock {

    JBMessage *message = [[self alloc] init];
    message.requestURL = URL;
    message.parameters = parameters;
    message.responseBlock = responseBlock;
    [message initialize];
    
    return message;
}

- (id)initWithParameters:(NSDictionary *)parameters
           responseBlock:(JBResponseBlock)responseBlock {
    
    NSAssert(baseUrlString, @"You must register base url in order to make request!");
    
    if (self = [super init]) {
        
        self.parameters = parameters;
        self.responseBlock = responseBlock;
        
        [self initialize];
    }
    
    return self;
}

- (id)init {

    if (self = [super init]) {
        
        [self initialize];
    }
    return self;
}

- (void)initialize {

    _filename = @"filename";
    _fileURL = nil;
    _authorizationToken = nil;
    _httpMethod = JBHTTPMethodPOST;
    _responseSerializer = JBResponseSerializerTypeHTTP;
    _shouldParseResponseOnMainQueue = YES;
    _timeoutInterval = 60.0f;

    __weak id this = self;
    _willResignObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                                            object:nil
                                                                             queue:nil
                                                                        usingBlock:^(NSNotification *note) {
                                                                            
                                                                            __strong typeof(self) strongThis = this;
                                                                            if (strongThis.operation.isExecuting) {
                                                                                [strongThis.operation cancel];
                                                                            }
                                                                        }];
}

#pragma mark - Operations

- (void)start {
    
    _isExecuting = YES;
    _isFinished = NO;
    
    [self operationDidStart];
}

- (void)cancel {
    
    _isCancelled = YES;
    [self.operation cancel];
    self.operation = nil;
}

- (BOOL) isConcurrent {
    return YES;
}

- (BOOL) isExecuting {
    return _isExecuting;
}

- (BOOL) isFinished {
    return _isFinished;
}

- (void)operationDidStart {
    [self executeRequest];
}

- (void)operationDidFinish {
    
    if (!_isExecuting) return;
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Executing Request

- (void)executeRequest {
    
    NSURLRequest *request = [self urlRequest];
    AFHTTPRequestOperationManager *manager = [self requestOperationManager];
    
    __weak id this = self;
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request
                                                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                             
                                                                             __strong JBMessage *strongThis = this;
                                                                             [strongThis receivedResponse:responseObject error:nil];
                                                                             strongThis.operation = nil;
                                                                             
                                                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#ifdef DEBUG
                                                                             NSString *response = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
                                                                             if (response && response.length) { NSLog(@"Response error: %@", response); }
#endif
                                                                             __strong JBMessage *strongThis = this;
                                                                             [strongThis receivedResponse:operation.responseData error:error];
                                                                             strongThis.operation = nil;
                                                                         }];

    [operation setUploadProgressBlock:self.uploadBlock];
    [operation setDownloadProgressBlock:self.downloadBlock];
    
    if (self.outputFileStreamPath) {
        [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:self.outputFileStreamPath append:NO]];
    }
    
    if (!_shouldParseResponseOnMainQueue) {
        [operation setCompletionQueue:jb_message_completion_callback_queue()];
    }
    
    if (self.shouldContinueAsBackgroundTask) {
        
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            __strong typeof(self) strongThis = this;
            [strongThis.operation resume];
        }];
    }
    
    [manager.operationQueue addOperation:operation];
}

#pragma mark - Handling Response

- (void)receivedResponse:(id)result error:(NSError *)error {
    
    NSError *parseError = nil;
    id parsedObject = nil;
    
    if (result && !error) {
        parsedObject = [self parseResponse:result error:&parseError];
        error = parseError;
    }
    else if (result) {
        parsedObject = [self parseResponse:result error:nil];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.responseBlock) {
            self.responseBlock(parsedObject, error);
        }
    });
    
    [self operationDidFinish];
}

- (id)parseResponse:(id)rawResponse error:(NSError *__autoreleasing *)error{
    
    if ([rawResponse isKindOfClass:[NSData class]]) {
        
        NSError *jsonError = nil;
        id response = [NSJSONSerialization JSONObjectWithData:rawResponse
                                                      options:0
                                                        error:&jsonError];
        if (error) {
            *error = jsonError;
        }
        
#ifdef DEBUG
        if(jsonError) { NSLog(@"%@, %@", [jsonError localizedDescription], [[NSString alloc] initWithData:rawResponse encoding:NSUTF8StringEncoding]); }
#endif
        return response;
    }
    return rawResponse;
}

@end

@implementation JBMessage (VCMessageCenter)

- (void)send {

    [[[self class] sharedQueue] addOperation:self];
}

@end
