//
//  VJBMessage.m
//  JBMessage
//
//  Created by Josip Bernat on 25/03/14.
//  Copyright (c) 2014 Josip-Bernat. All rights reserved.
//

#import "JBMessage.h"
#import "AFHTTPRequestOperationManager.h"

JBHTTPMethod const JBHTTPMethodGET      = @"GET";
JBHTTPMethod const JBHTTPMethodPOST     = @"POST";
JBHTTPMethod const JBHTTPMethodPUT      = @"PUT";
JBHTTPMethod const JBHTTPMethodDELETE   = @"DELETE";

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
}

#pragma mark - Shared Queue
+ (NSOperationQueue *)sharedQueue;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@interface JBMessage (Connection)

- (AFHTTPRequestOperationManager *)requestOperationManager;
- (AFHTTPResponseSerializer <AFURLResponseSerialization> *)httpResponseSerializer;
- (AFHTTPRequestSerializer <AFURLRequestSerialization> *)httpRequestSerializer;
- (NSString *)actionUrlString;
- (NSMutableURLRequest *)urlRequest;

@end


@implementation JBMessage

#pragma mark - Memory Management

- (void) dealloc {
    _responseBlock = nil;
    _uploadBlock = nil;
}

#pragma mark - Shared Queue

+ (NSOperationQueue *)sharedQueue {
    
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    });
    
    return queue;
}

#pragma mark - URL Registration

static NSString *baseUrlString = nil;

+ (void)registerBaseUrl:(NSString *)baseUrl {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseUrlString = baseUrl;
    });
}

+ (void)requsterMaxNumberOfConcurrentMessages:(NSUInteger)maxConcurrentMessages {

    [[JBMessage sharedQueue] setMaxConcurrentOperationCount:maxConcurrentMessages];
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
}

#pragma mark - Background Task

- (void)beginBackgroundTask {
    
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
}

- (void)endBackgroundTask {
    
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
}

#pragma mark - Operations

-(void) start {
    
    _isExecuting = YES;
    _isFinished = NO;
    
    [self operationDidStart];
}

- (void) finish {
    [self endBackgroundTask];
}

- (void) cancel {
    _isCancelled = YES;
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
    
    [self finish];
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
                                                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#ifdef DEBUG
                                                                             NSString *response = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
                                                                             if (response) { NSLog(@"Response error: %@", response); }
#endif
                                                                             __strong JBMessage *strongThis = this;
                                                                             [strongThis receivedResponse:operation.responseData error:error];
                                                                         }];

    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        __strong JBMessage *strongThis = this;
        if (strongThis.uploadBlock) {
            strongThis.uploadBlock(bytesWritten, (NSInteger)totalBytesWritten, (NSInteger)totalBytesExpectedToWrite);
        }
    }];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        __strong JBMessage *strongThis = this;
        if (strongThis.downloadBlock) {
            strongThis.downloadBlock(bytesRead, (NSInteger)totalBytesRead, (NSInteger)totalBytesExpectedToRead);
        }
    }];
    
    if (!_shouldParseResponseOnMainQueue) {
        [operation setCompletionQueue:jb_message_completion_callback_queue()];
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
        self.responseBlock(parsedObject, error);
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

@implementation JBMessage (Connection)

#pragma mark - Connection Helpers

- (AFHTTPRequestOperationManager *)requestOperationManager {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.responseSerializer = [self httpResponseSerializer];
    manager.requestSerializer = [self httpRequestSerializer];
    
    if (self.authorizationToken) {
        [manager.requestSerializer setValue:self.authorizationToken forHTTPHeaderField:@"Token"];
    }
    
    if (self.username && self.username.length &&
        self.password && self.password.length) {
        
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.username
                                                                  password:self.password];
    }
    
    return manager;
}

- (AFHTTPResponseSerializer <AFURLResponseSerialization> *)httpResponseSerializer {
    
    switch (self.responseSerializer) {
        case JBResponseSerializerTypeCompound:
            return [AFCompoundResponseSerializer serializer];
            
        case JBResponseSerializerTypeHTTP:
            return [AFHTTPResponseSerializer serializer];
            
        case JBResponseSerializerTypeImage:
            return [AFImageResponseSerializer serializer];
            
        case JBResponseSerializerTypeJSON:
            return [AFJSONResponseSerializer serializer];
            
        case JBResponseSerializerTypePropertyList:
            return [AFPropertyListResponseSerializer serializer];
            
        case JBResponseSerializerTypeXMLParser:
            return [AFXMLParserResponseSerializer serializer];
            
        default:
            break;
    }
}

- (AFHTTPRequestSerializer <AFURLRequestSerialization> *)httpRequestSerializer {

    switch (self.requestSerializer) {
        case JBRequestSerializerTypeHTTP:
            return [AFHTTPRequestSerializer serializer];
            break;
        
        case JBRequestSerializerTypeJSON:
            return [AFJSONRequestSerializer serializer];
            break;
            
        case JBRequestSerializerTypePropertyList:
            return [AFPropertyListRequestSerializer serializer];
            break;
            
        default:
            break;
    }
}

- (NSString *)actionUrlString {
    
    return (self.requestURL ?
            (self.action ?
             [[self.requestURL absoluteString] stringByAppendingString:self.action] :
             [self.requestURL absoluteString]) :
            [NSString stringWithFormat:@"%@%@", baseUrlString, self.action]);
}

- (NSMutableURLRequest *)urlRequest {
    
    AFHTTPRequestOperationManager *manager = [self requestOperationManager];
    NSMutableURLRequest *request = nil;
    
    if (self.httpMethod == JBHTTPMethodGET || !self.fileURL) {
        
        NSError *error = nil;
        request = [manager.requestSerializer requestWithMethod:self.httpMethod
                                                     URLString:[self actionUrlString]
                                                    parameters:self.parameters
                                                         error:&error];
#ifdef DEBUG
        if (error) { NSLog(@"Error while creating request: %@", error); }
#endif
    }
    else {
        
        __weak id this = self;
        NSError *multpartError = nil;
        request = [manager.requestSerializer multipartFormRequestWithMethod:self.httpMethod
                                                                  URLString:[self actionUrlString]
                                                                 parameters:self.parameters
                                                  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                      
                                                      __strong JBMessage *strongThis = this;
                                                      [formData appendPartWithFileURL:strongThis.fileURL
                                                                                 name:strongThis.filename
                                                                                error:nil];
                                                  } error:&multpartError];
#ifdef DEBUG
        if (multpartError) { NSLog(@"Error while creating multpart form request: %@", multpartError); }
#endif
    }
    
    return request;
}

@end
