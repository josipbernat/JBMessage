JBMessage
=========

JBMessage is simple iOS networking wrapper based on AFNetworking. It allows you to simplify your networking code and forces you to rearrange each API call into separate class.

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like JBMessage in your projects.

#### Podfile

```ruby
platform :ios, '6.0'
pod 'JBMessage', '~> 1.0'
```

## USAGE

### `GET` Request
```objective-c
    JBMessage *message = [JBMessage messageWithURL:[NSURL URLWithString:@"http://example.com/resources.json"]
                                        parameters:@{@"foo": @"bar"}
                                     responseBlock:^(id responseObject, NSError *error) {
                                         NSLog(@"%@", responseObject);
                                     }];
    message.httpMethod = JBHTTPMethodGET;
    [message send];
```

### `POST` Request
```objective-c
    JBMessage *message = [JBMessage messageWithURL:[NSURL URLWithString:@"http://example.com/resources.json"]
                                        parameters:@{@"foo": @"bar"}
                                     responseBlock:^(id responseObject, NSError *error) {
                                         NSLog(@"%@", responseObject);
                                     }];
    message.httpMethod = JBHTTPMethodPOST;
    [message send];
```

### `PUT` Request
```objective-c
    JBMessage *message = [JBMessage messageWithURL:[NSURL URLWithString:@"http://example.com/resources.json"]
                                        parameters:@{@"foo": @"bar"}
                                     responseBlock:^(id responseObject, NSError *error) {
                                         NSLog(@"%@", responseObject);
                                     }];
    message.httpMethod = JBHTTPMethodPUT;
    [message send];
```

### `DELETE` Request
```objective-c
    JBMessage *message = [JBMessage messageWithURL:[NSURL URLWithString:@"http://example.com/resources.json"]
                                        parameters:@{@"foo": @"bar"}
                                     responseBlock:^(id responseObject, NSError *error) {
                                         NSLog(@"%@", responseObject);
                                     }];
    message.httpMethod = JBHTTPMethodDELETE;
    [message send];
```
