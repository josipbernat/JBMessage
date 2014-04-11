//
//  JBViewController.m
//  JBMessage
//
//  Created by Josip Bernat on 26/03/14.
//  Copyright (c) 2014 Jospi Bernat. All rights reserved.
//

#import "JBViewController.h"
#import "JBMessage.h"

@interface JBViewController ()

@end

@implementation JBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [JBMessage registerBaseUrl:@"http://example.com/"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Selectors

- (IBAction)onGetWithBaseURL:(id)sender {

    JBMessage *message = [JBMessage messageWithParameters:@{@"foo": @"bar"}
                                            responseBlock:^(id responseObject, NSError *error) {
                                                NSLog(@"%@", responseObject);
                                            }];
    message.httpMethod = JBHTTPMethodGET;
    message.action = @"resources.json";
    [message send];
}

- (IBAction)onPostWithBaseURL:(id)sender {

    JBMessage *message = [JBMessage messageWithParameters:@{@"foo": @"bar"}
                                            responseBlock:^(id responseObject, NSError *error) {
                                                NSLog(@"%@", responseObject);
                                            }];
    message.httpMethod = JBHTTPMethodPOST;
    message.action = @"resources.json";
    [message send];
}

- (IBAction)onPutWithBaseURL:(id)sender {

    JBMessage *message = [JBMessage messageWithParameters:@{@"foo": @"bar"}
                                            responseBlock:^(id responseObject, NSError *error) {
                                                NSLog(@"%@", responseObject);
                                            }];
    message.httpMethod = JBHTTPMethodPUT;
    message.action = @"resources.json";
    [message send];
}

- (IBAction)onDeleteWithBaseURL:(id)sender {

    JBMessage *message = [JBMessage messageWithParameters:@{@"foo": @"bar"}
                                            responseBlock:^(id responseObject, NSError *error) {
                                                NSLog(@"%@", responseObject);
                                            }];
    message.httpMethod = JBHTTPMethodDELETE;
    message.action = @"resources.json";
    [message send];
}

- (IBAction)onGetWithRequestURL:(id)sender {

    JBMessage *message = [JBMessage messageWithURL:[NSURL URLWithString:@"http://example.com/resources.json"]
                                        parameters:@{@"foo": @"bar"}
                                     responseBlock:^(id responseObject, NSError *error) {
                                         NSLog(@"%@", responseObject);
                                     }];
    message.httpMethod = JBHTTPMethodGET;
    [message send];
}

- (IBAction)onPostWithRequestURL:(id)sender {

    JBMessage *message = [JBMessage messageWithURL:[NSURL URLWithString:@"http://example.com/resources.json"]
                                        parameters:@{@"foo": @"bar"}
                                     responseBlock:^(id responseObject, NSError *error) {
                                         NSLog(@"%@", responseObject);
                                     }];
    message.httpMethod = JBHTTPMethodPOST;
    [message send];
}

- (IBAction)onPutWithRequestURL:(id)sender {

    JBMessage *message = [JBMessage messageWithURL:[NSURL URLWithString:@"http://example.com/resources.json"]
                                        parameters:@{@"foo": @"bar"}
                                     responseBlock:^(id responseObject, NSError *error) {
                                         NSLog(@"%@", responseObject);
                                     }];
    message.httpMethod = JBHTTPMethodPUT;
    [message send];
}

- (IBAction)onDeleteWithRequestURL:(id)sender {

    JBMessage *message = [JBMessage messageWithURL:[NSURL URLWithString:@"http://example.com/resources.json"]
                                        parameters:@{@"foo": @"bar"}
                                     responseBlock:^(id responseObject, NSError *error) {
                                         NSLog(@"%@", responseObject);
                                     }];
    message.httpMethod = JBHTTPMethodDELETE;
    [message send];
}

@end
