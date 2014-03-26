//
//  VCMessage.m
//  VectorChat
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

@interface JBMessage () {

    BOOL _isCancelled;
    BOOL _isFinished;
    BOOL _isExecuting;
}

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, strong) NSDictionary *parameters;

@end

@implementation JBMessage

#pragma mark - Memory Management

- (void) dealloc {
    _responseBlock = nil;
    _uploadBlock = nil;
}

#pragma mark - URL Registration

static NSString *baseUrlString = nil;
+ (void)registerBaseUrl:(NSString *)baseUrl {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseUrlString = baseUrl;
    });
}

#pragma mark - Initialization

+ (instancetype)messageWithParameters:(NSDictionary *) parameters
                        responseBlock:(JBResponseBlock) responseBlock {
    
    JBMessage *message = [[self alloc] initWithParameters:parameters
                                            responseBlock:responseBlock];
    return message;
}

- (id)initWithParameters:(NSDictionary *)parameters
           responseBlock:(JBResponseBlock)responseBlock {
    
    if (self = [super init]) {
        
        self.parameters = parameters;
        self.responseBlock = responseBlock;
        
        _filename = @"filename";
        _fileURL = nil;
        _httpMethod = JBHTTPMethodPOST;
        _shouldCompleteOnMainQueue = YES;
    }
    
    return self;
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
    
    [self executeRequest];
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

    __block NSError *uploadError = nil;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    __weak id this = self;
    
    NSMutableURLRequest *request = nil;
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", baseUrlString, self.action];
    if (self.httpMethod == JBHTTPMethodGET || !self.fileURL) {
        
        NSError *error = nil;
        request = [manager.requestSerializer requestWithMethod:self.httpMethod
                                                     URLString:urlString
                                                    parameters:self.parameters
                                                         error:&error];
#ifdef DEBUG
        if (error) {
            NSLog(@"Error while creating NSMutableRequest: %@", error);
        }
#endif
    }
    else {
    
        request = [manager.requestSerializer multipartFormRequestWithMethod:self.httpMethod
                                                                  URLString:urlString
                                                                 parameters:[self parameters]
                                                  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                      
                                                      __strong JBMessage *strongThis = this;
                                                      [formData appendPartWithFileURL:strongThis.fileURL
                                                                                 name:strongThis.filename
                                                                                error:&uploadError];
                                                  } error:nil];
    }
    
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request
                                                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                             
                                                                             __strong JBMessage *strongThis = this;
                                                                             [strongThis receivedResponse:responseObject error:nil];
                                                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                             
                                                                             __strong JBMessage *strongThis = this;
                                                                             [strongThis receivedResponse:nil error:error];
                                                                         }];
    
    
    [operation setUploadProgressBlock:self.uploadBlock];
    
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
    
    if (_shouldCompleteOnMainQueue) {
        //return response on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            self.responseBlock(parsedObject, error);
        });
    }
    else {
        self.responseBlock(parsedObject, error);
    }
    
    [self operationDidFinish];
}


- (id)parseResponse:(id)rawResponse error:(NSError *__autoreleasing *)error{
    
    if ([rawResponse isKindOfClass:[NSData class]]) {
        
        NSError *jsonError = nil;
        id response = [NSJSONSerialization JSONObjectWithData:rawResponse
                                                      options:0
                                                        error:&jsonError];
        *error = jsonError;
        
#ifdef DEBUG
        if(jsonError) {
            NSLog(@"%@, %@", [jsonError localizedDescription], [[NSString alloc] initWithData:rawResponse encoding:NSUTF8StringEncoding]);
        }
#endif
        return response;
    }
    return rawResponse;
}

@end

@implementation JBMessage (VCMessageCenter)

+ (NSOperationQueue *)sharedQueue {
    
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    });
    
    return queue;
}

- (void)send {

    [[[self class] sharedQueue] addOperation:self];
}

@end
