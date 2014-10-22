//
//  JBMessage+NSURLConnection.h
//  JBMessage
//
//  Created by Josip Bernat on 01/10/14.
//  Copyright (c) 2014 Jospi Bernat. All rights reserved.
//

#import "JBMessage.h"

@class AFHTTPRequestOperationManager;
@class AFHTTPResponseSerializer;
@class AFHTTPRequestSerializer;

@protocol AFURLResponseSerialization;
@protocol AFURLRequestSerialization;

@interface JBMessage (NSURLConnection)

- (AFHTTPRequestOperationManager *)requestOperationManager;
- (AFHTTPResponseSerializer <AFURLResponseSerialization> *)httpResponseSerializer;
- (AFHTTPRequestSerializer <AFURLRequestSerialization> *)httpRequestSerializer;

- (NSString *)actionUrlString;
- (NSMutableURLRequest *)urlRequest;

@end
