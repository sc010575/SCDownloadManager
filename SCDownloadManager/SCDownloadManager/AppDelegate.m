//
//  AppDelegate.m
//  SCDownloadManager
//
//  Created by Suman Chatterjee on 22/03/2015.
//  Copyright (c) 2015 Suman Chatterjee. All rights reserved.
//

#import "AppDelegate.h"
#import "Dropbox.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSString *token = [[NSUserDefaults standardUserDefaults] valueForKey:accessToken];
    
    NSString *controllerId = token ? @"evenDetails" : @"Login";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:controllerId];
    
    // always assumes token is valid - should probably check in a real app
    if (token) {
        [self.window setRootViewController:initViewController];
    } else {
        [(UINavigationController *)self.window.rootViewController pushViewController:initViewController animated:NO];
    }
    return YES;
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - OAuth login flow and url scheme handling

-(BOOL)application:(UIApplication *)application
           openURL:(NSURL *)url
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation
{
    if ([[url scheme] isEqualToString:@"eventpilot"]) {
        [self exchangeRequestTokenForAccessToken];
    }
    return NO;
}

- (void)exchangeRequestTokenForAccessToken
{
    // OAUTH Step 3 - exchange request token for user access token
    [Dropbox exchangeTokenForUserAccessTokenURLWithCompletionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
            if (httpResp.statusCode == 200) {
                
                
                NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary *accessTokenDict = [Dropbox dictionaryFromOAuthResponseString:response];
                
                [[NSUserDefaults standardUserDefaults] setObject:accessTokenDict[oauthTokenKey] forKey:accessToken];
                [[NSUserDefaults standardUserDefaults] setObject:accessTokenDict[oauthTokenKeySecret] forKey:accessTokenSecret];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                
                //REquest for download Json File
//                [self requestForDownLoad];
                
                
                // now load main part of application
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSString *segueId = @"evenDetails";
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    UITabBarController *initViewController = [storyboard instantiateViewControllerWithIdentifier:segueId];
                    
                    UINavigationController *nav = (UINavigationController *) self.window.rootViewController;
                    nav.navigationBar.hidden = YES;
                    [nav pushViewController:initViewController animated:NO];
                });
                
            } else {
                // HANDLE BAD RESPONSE //
                NSLog(@"exchange request for access token unexpected response %@",
                      [NSHTTPURLResponse localizedStringForStatusCode:httpResp.statusCode]);
            }
        } else {
            // ALWAYS HANDLE ERRORS :-] //
        }
    }];
}



@end
