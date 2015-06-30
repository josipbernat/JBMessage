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
#import "JBMessageCenter.h"

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
    id _willResignObserver;
}

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
    
    NSAssert([JBMessageCenter baseURL], @"You must register base url in order to make request!");
    
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

#pragma mark - Operation Control

- (void)operationDidStart {
    [self executeRequest];
}

#pragma mark - Executing Request

- (void)executeRequest {
    
    NSURLRequest *request = [self urlRequest];
    AFHTTPRequestOperationManager *manager = [self requestOperationManager];
    
    if (self.allowsInvalidCertificates) {
        manager.securityPolicy.allowInvalidCertificates = YES;
    }
    
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
    self.operation = operation;
    
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

@implementation JBMessage (JBMessageCenter)

- (void)send {

    [[JBMessageCenter sharedCenter] enqueueMessage:self];
}

@end

@implementation JBMessage (Deprecated_Methods)

+ (void)requsterMaxNumberOfConcurrentMessages:(NSUInteger)maxConcurrentMessages DEPRECATED_ATTRIBUTE {
    
    NSOperationQueue *queue = [[JBMessageCenter sharedCenter] queue];
    queue.maxConcurrentOperationCount = maxConcurrentMessages;
}

+ (JBMessageReachabilityStatus)reachabilityStatus DEPRECATED_ATTRIBUTE {
    return[JBMessageCenter reachabilityStatus];
}

+ (BOOL)isInternetReachable DEPRECATED_ATTRIBUTE {
    return [JBMessageCenter isInternetReachable];
}

+ (void)registerBaseUrl:(NSString *)baseUrl DEPRECATED_ATTRIBUTE {
    [JBMessageCenter setBaseURL:baseUrl];
}

+ (NSString *)registratedBaseUrl DEPRECATED_ATTRIBUTE {
    return [JBMessageCenter baseURL];
}

@end
