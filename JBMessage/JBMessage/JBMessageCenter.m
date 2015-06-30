//
//  JBMessageCenter.m
//  JBMessage
//
//  Created by Josip Bernat on 6/30/15.
//  Copyright (c) 2015 Jospi Bernat. All rights reserved.
//

#import "JBMessageCenter.h"
#import "AFHTTPRequestOperationManager.h"
#import "JBMessage.h"

@interface JBMessageCenter ()

@property (strong, nonatomic) NSString *baseURL;

@end

@implementation JBMessageCenter

+ (void)load {
    [self sharedCenter];
}

#pragma mark - Shared Instance

+ (instancetype)sharedCenter {

    static JBMessageCenter *instance = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Initialization

- (instancetype)init {

    if (self = [super init]) {
        
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
        [_queue setName:@"com.jbmessage.shared_queue"];
    }
    return self;
}

#pragma mark - URL Registration

+ (void)setBaseURL:(NSString *)baseUrl {

    JBMessageCenter *instance = [self sharedCenter];
    instance.baseURL = baseUrl;
}

+ (NSString *)baseURL {
    
    JBMessageCenter *instance = [self sharedCenter];
    return instance.baseURL;
}

#pragma mark - Reachability

- (void)updateReachability {
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:JBMessageReachabilityStatusChangedNotification
                                                            object:nil
                                                          userInfo:@{JBMessageReachabilityStatusKey: @(status)}];
    }];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (JBMessageReachabilityStatus)reachabilityStatus {
    return (JBMessageReachabilityStatus) [[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus];
}

+ (BOOL)isInternetReachable {
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

#pragma mark - Enqueue

- (void)enqueueMessage:(JBMessage *)message {
    
    [_queue addOperation:message];
}

@end
