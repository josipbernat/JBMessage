//
//  JBViewController.h
//  JBMessage
//
//  Created by Josip Bernat on 26/03/14.
//  Copyright (c) 2014 Jospi Bernat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JBViewController : UIViewController

#pragma mark - Button Selectors
- (IBAction)onGetWithBaseURL:(id)sender;
- (IBAction)onPostWithBaseURL:(id)sender;
- (IBAction)onPutWithBaseURL:(id)sender;
- (IBAction)onDeleteWithBaseURL:(id)sender;

- (IBAction)onGetWithRequestURL:(id)sender;
- (IBAction)onPostWithRequestURL:(id)sender;
- (IBAction)onPutWithRequestURL:(id)sender;
- (IBAction)onDeleteWithRequestURL:(id)sender;
- (IBAction)onDownloadWithRequestURL:(id)sender;

@end
