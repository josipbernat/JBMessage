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

typedef NS_ENUM(NSInteger, JBResponseSerializerType) {
    JBResponseSerializerTypeHTTP = 0,       /// AFHTTPResponseSerializer
    JBResponseSerializerTypeJSON,           /// AFJSONResponseSerializer
    JBResponseSerializerTypeXMLParser,      /// AFXMLParserResponseSerializer
    JBResponseSerializerTypePropertyList,   /// AFPropertyListResponseSerializer
    JBResponseSerializerTypeImage,          /// AFImageResponseSerializer
    JBResponseSerializerTypeCompound        /// AFCompoundResponseSerializer
};

typedef NS_ENUM(NSInteger, JBRequestSerializerType) {
    JBRequestSerializerTypeHTTP = 0,        /// AFHTTPRequestSerializer
    JBRequestSerializerTypeJSON,            /// AFJSONRequestSerializer
    JBRequestSerializerTypePropertyList     /// AFPropertyListRequestSerializer
};

/**
 *  Block object containing response object and error. Used as callback when request is done with execution.
 *
 *  @param responseObject The response object. Can be a single model or a collection depending on the message.
 *  @param error          The error object describing error which occurred while executing the request.
 */
typedef void (^JBResponseBlock)(id responseObject, NSError *error);

/**
 *  Block object containing information about uploaded bytes over the network.
 *
 *  @param bytesWritten              The number of bytes written since the last time the upload progress block was called.
 *  @param totalBytesWritten         The total bytes written.
 *  @param totalBytesExpectedToWrite The total bytes expected to be written during the request, as initially determined by the length of the HTTP body.
 */
typedef void (^JBUploadBlock)(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite);

/**
 *  Block object containing information about downloaded bytes over the netwkor.
 *
 *  @param bytesRead                The number of bytes read since the last time the download progress block was called.
 *  @param totalBytesRead           The total bytes read.
 *  @param totalBytesExpectedToRead The total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object.
 */
typedef void (^JBDownloadBlock)(NSUInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead);

@interface JBMessage : NSOperation

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
@property (nonatomic, strong) NSDictionary *parameters;

/**
 *  Authorization token to be send in header values. Default is nil.
 */
@property (nonatomic, strong) NSString *authorizationToken;

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

#pragma mark - URL Registration

/**
 *  Register baseUrl in order to enable request execution. The easiest way is to call it directly from application:didFinishLaunchingWithOptions:. Once it's set it cannot be canged.
 *
 *  @param baseUrl Url to register, i.e. http://example.com/api/.
 */
+ (void)registerBaseUrl:(NSString *)baseUrl;

/**
 *  Sets number of concurrent messages in messages queue.
 *
 *  @param maxConcurrentMessages Number of concurrent messages to be set.
 */
+ (void)requsterMaxNumberOfConcurrentMessages:(NSUInteger)maxConcurrentMessages;

#pragma mark - Operation Controll

/**
 *  Called when operation has started with the job inside NSOperationQueue. You may wish to override this method on your subclass if you need to make some aditional config before executing request. You must call super operationDidStart in order to execute request.
 */
- (void)operationDidStart;

/**
 *  Called when request is finised with execution and parsing data. In your subclass you can override this method in order to make aditional response validation, etc. You must call super operadionDidFinish in order to finish the operation. Not calling super method will cause not releasing the operation and memory leak.
 */
- (void)operationDidFinish;

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
