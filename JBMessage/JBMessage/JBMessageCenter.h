//
//  JBMessageCenter.h
//  JBMessage
//
//  Created by Josip Bernat on 6/30/15.
//  Copyright (c) 2015 Jospi Bernat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JBMessageDefines.h"

@class JBMessage;

@interface JBMessageCenter : NSObject

@property (nonatomic, strong) NSOperationQueue *queue;

#pragma mark - Shared Instance
/**
 *  Shared instance of message center. In case there is no existing instance new one will be created.
 *
 *  @return Instance of message center.
 */
+ (instancetype)sharedCenter;

#pragma mark - URL Registration
/**
 *  Register baseUrl in order to enable request execution. The easiest way is to call it directly from application:didFinishLaunchingWithOptions:. Changable at any time.
 *
 *  @param baseUrl Url to register, i.e. http://example.com/api/
 */
+ (void)setBaseURL:(NSString *)baseUrl;

/**
 *  Registrated base URL.
 *
 *  @return String with registrated base URL.
 */
+ (NSString *)baseURL;

#pragma mark - Reachability
/**
 *  Current reachability status.
 *
 *  @return JBMessageReachabilityStatus value holding current reachability status.
 */
+ (JBMessageReachabilityStatus)reachabilityStatus;

/**
 *  Determents if internet is reachable or not using reachabilityStatus.
 *
 *  @return Boolean value determening if internet is reachable.
 */
+ (BOOL)isInternetReachable;


#pragma mark - Enqueue
/**
 *  Enqueues given message.
 *
 *  @param message Message object to be enqueued. Must not be nil.
 */
- (void)enqueueMessage:(JBMessage *)message;


@end
