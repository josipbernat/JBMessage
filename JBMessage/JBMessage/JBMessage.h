//
//  JBMessage.h
//  JBMessage
//
//  Created by Josip Bernat on 25/03/14.
//  Copyright (c) 2014 Josip-Bernat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JBMessageCenter.h"
#import "JBOperation.h"

typedef NSString *JBHTTPMethod;

extern JBHTTPMethod const JBHTTPMethodGET;
extern JBHTTPMethod const JBHTTPMethodPOST;
extern JBHTTPMethod const JBHTTPMethodPUT;
extern JBHTTPMethod const JBHTTPMethodDELETE;

/**
 *  NSNotification posted when reachability status changes. UserInfo dictionary contains NSNumber with JBMessageReachabilityStatus under JBMessageReachabilityStatusKey key.
 */
extern NSString * const JBMessageReachabilityStatusChangedNotification;

/**
 *  UserInfo dictionary key which contains JBMessageReachabilityStatus status value.
 */
extern NSString * const JBMessageReachabilityStatusKey;

@class AFHTTPRequestOperation;

@interface JBMessage : JBOperation

/**
 *  An operation used for the request.
 */
@property (nonatomic, strong) AFHTTPRequestOperation *operation;

/**
 *  Sets callback block to be called when message is done with execution. Depending on shouldCompleteOnMainQueue property, it will execute on main thread of queue thread.
 */
@property (copy) JBResponseBlock responseBlock;

/**
 *  Sets callback block to be called when an undetermined number of bytes have been uploaded to the server. This block may be called multiple times, and will execute on the main thread.
 */
@property (copy) JBUploadBlock uploadBlock;

/**
 *  Sets callback block to be called when an undetermined number of bytes have been downloaded from the server. This block may be called multiple times, and will execute on the main thread.
 */
@property (copy) JBDownloadBlock downloadBlock;

/**
 *  Action for the request, i.e login.php.
 */
@property (nonatomic, copy) NSString *action;

/**
 *  URL used for the request. If set the registrated base URL is not used.
 */
@property (nonatomic, strong) NSURL *requestURL;

/**
 *  HTTP method for the request. Default is JBHTTPMethodPOST.
 */
@property (nonatomic, readwrite) JBHTTPMethod httpMethod;

/**
 *  Determents whether parseResponse:error: method should be called on main queue or not. Setting to NO enables you to do heavy parsing on background queue. Default is YES.
 */
@property (nonatomic, readwrite) BOOL shouldParseResponseOnMainQueue;

/**
 *  Boolean value determening whether operation should continue network task in background. Default is NO. Setting this property when message is in execution will have no effect.
 */
@property (nonatomic, readwrite) BOOL shouldContinueAsBackgroundTask;

/**
 *  Boolean value determening wheter operation should allow invalid (https) certificates. Default value is NO.
 */
@property (nonatomic, readwrite) BOOL allowsInvalidCertificates;

/**
 *  A file URL for the multipart request. Deprecated from V.1.0.9. See inputFileURL and outputFileStreamPath.
 */
@property (nonatomic, copy) NSURL *fileURL __attribute__((deprecated));

/**
 *  Input file URL used for uploading request.
 */
@property (nonatomic, copy) NSURL *inputFileURL;

/**
 *  Output file stream path used for downloading request.
 */
@property (nonatomic, copy) NSString *outputFileStreamPath;

/**
 *  A filename field used in multpart request. Default is "filename".
 */
@property (nonatomic, copy) NSString *filename;

/**
 *  Parameters to be send in the request.
 */
@property (nonatomic, strong) NSDictionary *parameters;

/**
 *  Authorization token to be send in header values. Default is nil.
 */
@property (nonatomic, strong) NSString *authorizationToken;

/**
 *  Header values for request. Default is nil.
 */
@property (nonatomic, strong) NSDictionary *headerValues;

/**
 *  Basic authorization username.
 */
@property (nonatomic, strong) NSString *username;

/**
 *  Basic authorization password.
 */
@property (nonatomic, strong) NSString *password;

/**
 *  Response serializer used for handling request response. Default is JBResponseSerializerTypeHTTP.
 */
@property (nonatomic, readwrite) JBResponseSerializerType responseSerializer;

/**
 *  Request serializer used for formatting http body. Default is JBRequestSerializerTypeHTTP.
 */
@property (nonatomic, readwrite) JBRequestSerializerType requestSerializer;

/**
 *  Timeout interval of the message. Default is 60.0 seconds. Setting this property when message is in execution will have no effect.
 */
@property (nonatomic, readwrite) NSTimeInterval timeoutInterval;

#pragma mark - Initialization

/**
 *  Initializes the message with parameters
 *
 *  @param parameters       Web service parameters to be sent.
 *  @param responseBlock    Response callback. Will contain parsed objects depending on the message or an error if there was one.
 *
 *  @return an instance of JBMessage.
 */
+ (instancetype)messageWithParameters:(NSDictionary *) parameters
                        responseBlock:(JBResponseBlock) responseBlock;

/**
 *  Initializes the message with given URL and parameters.
 *
 *  @param URL           URL of web service. Will not be saved or retained for other requests.
 *  @param parameters    Web service parameters to be sent.
 *  @param responseBlock Response callback. Will contain parsed objects depending on the message or an error if there was one.
 *
 *  @return An instance of JBMessage.
 */
+ (instancetype)messageWithURL:(NSURL *)URL
                    parameters:(NSDictionary *)parameters
                 responseBlock:(JBResponseBlock) responseBlock;

/**
 *  Initializes the message with parameters
 *
 *  @param parameters       Web service parameters to be sent.
 *  @param responseBlock    Response callback. Will contain parsed objects depending on the message or an error if there was one.
 *
 *  @return an instance of JBMessage.
 */
- (id)initWithParameters:(NSDictionary *)parameters
           responseBlock:(JBResponseBlock) responseBlock;

#pragma mark - Parsing Response
/**
 *  Parses the raw response from the server and returns a callback.
 *
 *  @param rawResponse  Raw server response.
 *  @param error        Error generated by parsing.
 *
 *  @return returns RawResponse if JSON parsing fails by default. Override in subclasses to return other object types.
 */
- (id)parseResponse:(id)rawResponse error:(NSError **) error;

@end

@interface JBMessage (JBMessageCenter)

/**
 *  Enqueues message on message center and starts server communication. Uses shared operationQueue. Override this method in your subclass in case you need to use some other operation queue.
 */
- (void)send;

@end

@interface JBMessage (Deprecated_Methods)

/**
 *  Sets number of concurrent messages in messages queue. This method is deprecated since JBMessageCenter is introduced. Manipulate with center's queue.maxConcurrentOperationCount instead.
 *
 *  @param maxConcurrentMessages Number of concurrent messages to be set.
 */
+ (void)requsterMaxNumberOfConcurrentMessages:(NSUInteger)maxConcurrentMessages DEPRECATED_ATTRIBUTE;

/**
 *  Current reachability status.
 *
 *  @return JBMessageReachabilityStatus value holding current reachability status. This method is deprecated since JBMessageCenter is introduced. Use [JBMessageCenter reachabilityStatus] instead.
 */
+ (JBMessageReachabilityStatus)reachabilityStatus DEPRECATED_ATTRIBUTE;

/**
 *  Determents if internet is reachable or not using reachabilityStatus. This method is deprecated since JBMessageCenter is introduced. Use [JBMessageCenter isInternetReachable] instead.
 *
 *  @return Boolean value determening if internet is reachable.
 */
+ (BOOL)isInternetReachable DEPRECATED_ATTRIBUTE;

/**
 *  Register baseUrl in order to enable request execution. This method is deprecated since JBMessageCenter is introduced. Use [JBMessageCenter setBaseURL:] instead.
 *
 *  @param baseUrl Url to register, i.e. http://example.com/api/.
 */
+ (void)registerBaseUrl:(NSString *)baseUrl DEPRECATED_ATTRIBUTE;

/**
 *  Registrated baseUrl. This method is deprecated since JBMessageCenter is introduced. Use [JBMessageCenter baseURL] instead.
 *
 *  @return String containing URL.
 */
+ (NSString *)registratedBaseUrl DEPRECATED_ATTRIBUTE;

@end
