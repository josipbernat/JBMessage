//
//  JBMessage.h
//  JBMessage
//
//  Created by Josip Bernat on 25/03/14.
//  Copyright (c) 2014 Josip-Bernat. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString *JBHTTPMethod;

extern JBHTTPMethod const JBHTTPMethodGET;
extern JBHTTPMethod const JBHTTPMethodPOST;
extern JBHTTPMethod const JBHTTPMethodPUT;
extern JBHTTPMethod const JBHTTPMethodDELETE;

/**
 *  Response block object can be a single model or a collection depending on the message.
 */
typedef void (^JBResponseBlock)(id responseObject, NSError *error);

/**
 *  Upload block object containing information about upload progress. Can be called multiple times during the upload.
 */
typedef void (^JBUploadBlock)(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite);

@interface JBMessage : NSOperation

/**
 *  Response block to be called once the request finishes.
 */
@property (copy) JBResponseBlock responseBlock;

/**
 *  Upload block object called when upload sends bytes. Can be called multiply times during the upload.
 */
@property (copy) JBUploadBlock uploadBlock;

/**
 *  Action for the request, i.e login.php.
 */
@property (nonatomic, copy) NSString *action;

/**
 *  HTTP method for the request. Default is JBHTTPMethodPOST.
 */
@property (nonatomic, readwrite) JBHTTPMethod httpMethod;

/**
 *  Determents whether response block should be called on main queue or not. Setting to NO enables you to do heavy parsing on background queue. Default is YES.
 */
@property (nonatomic, readwrite) BOOL shouldCompleteOnMainQueue;

/**
 *  A file URL for the multipart request.
 */
@property (nonatomic, copy) NSURL *fileURL;

/**
 *  A filename field used in multpart request. Default is "filename".
 */
@property (nonatomic, copy) NSString *filename;

/**
 *  Parameters to be send in the request.
 */
@property (nonatomic, strong, readonly) NSDictionary *parameters;

#pragma mark - URL Registration

/**
 *  Register baseUrl in order to enable request execution. The easiest way is to call it directly from application:didFinishLaunchingWithOptions:.
 *
 *  @param baseUrl Url to register, i.e. http://example.com/api/.
 */
+ (void)registerBaseUrl:(NSString *)baseUrl;

#pragma mark - Initialization

/**
 *  Initializes the message with parameters
 *
 *  @param parameters       Web service parameters to be sent.
 *  @param responseBlock    Response callback. Will contain parsed objects depending on the message or an error if there was one.
 *
 *  @return an instance of VCMessage
 */
+ (instancetype)messageWithParameters:(NSDictionary *) parameters
                        responseBlock:(JBResponseBlock) responseBlock;

/**
 *  Initializes the message with parameters
 *
 *  @param parameters       Web service parameters to be sent.
 *  @param responseBlock    Response callback. Will contain parsed objects depending on the message or an error if there was one.
 *
 *  @return an instance of VCMessage
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
