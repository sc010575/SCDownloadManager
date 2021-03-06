//
//  AppDelegate.h
//  SCDownloadManager
//
//  Created by Suman Chatterjee on 22/03/2015.
//  Copyright (c) 2015 Suman Chatterjee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (copy) void (^backgroundSessionCompletionHandler)();

@end

