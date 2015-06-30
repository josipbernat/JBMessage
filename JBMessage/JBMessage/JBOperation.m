//
//  JBOperation.m
//  JBMessage
//
//  Created by Josip Bernat on 6/30/15.
//  Copyright (c) 2015 Jospi Bernat. All rights reserved.
//

#import "JBOperation.h"

@implementation JBOperation {

    BOOL _isCancelled;
    BOOL _isFinished;
    BOOL _isExecuting;
}

#pragma mark - Operation Control

- (void)start {
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = NO;
    [self didChangeValueForKey:@"isFinished"];
    
    [self operationDidStart];
}

- (void)cancel {
    
    _isCancelled = YES;
    [self operationDidCancel];
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

#pragma mark - Operation Control

- (void)operationDidStart {

}

- (void)operationDidFinish {
    
    if (!_isExecuting) return;
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)operationDidCancel {

}

@end
