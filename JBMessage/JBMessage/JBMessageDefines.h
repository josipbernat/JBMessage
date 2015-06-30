//
//  JBMessageDefines.h
//  JBMessage
//
//  Created by Josip Bernat on 6/30/15.
//  Copyright (c) 2015 Jospi Bernat. All rights reserved.
//

#ifndef JBMessage_JBMessageDefines_h
#define JBMessage_JBMessageDefines_h

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

typedef NS_ENUM(NSInteger, JBMessageReachabilityStatus) {
    JBMessageReachabilityStatusUnknown          = -1,   /// AFNetworkReachabilityStatusUnknown
    JBMessageReachabilityStatusNotReachable     = 0,    /// AFNetworkReachabilityStatusNotReachable
    JBMessageReachabilityStatusReachableViaWWAN = 1,     /// AFNetworkReachabilityStatusReachableViaWWAN
    JBMessageReachabilityStatusReachableViaWiFi = 2    /// AFNetworkReachabilityStatusReachableViaWiFi
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
typedef void (^JBUploadBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);

/**
 *  Block object containing information about downloaded bytes over the netwkor.
 *
 *  @param bytesRead                The number of bytes read since the last time the download progress block was called.
 *  @param totalBytesRead           The total bytes read.
 *  @param totalBytesExpectedToRead The total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object.
 */
typedef void (^JBDownloadBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);

#endif
