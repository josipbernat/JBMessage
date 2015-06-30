//
//  JBOperation.h
//  JBMessage
//
//  Created by Josip Bernat on 6/30/15.
//  Copyright (c) 2015 Jospi Bernat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JBOperation : NSOperation

#pragma mark - Operation Control

/**
 *  Called when operation has started with the job inside NSOperationQueue. You should override this method inside your subclass in order to make your job.
 */
- (void)operationDidStart;

/**
 *  Typically you call this method when your operation is done with it's work. If overridden you must call super. Not calling super method will cause not releasing the operation and memory leak.
 */
- (void)operationDidFinish;

/**
 *  Called once operation has been canceled.
 */
- (void)operationDidCancel;

@end
