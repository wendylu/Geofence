//
//  AppDelegate.m
//  GeoFence
//
//  Created by Wendy Lu on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "GeoFencer.h"
#import "ViewController.h"

@implementation AppDelegate {
    ViewController *vc;
    GeoFencer *geoFencer;
}

@synthesize window = _window;

- (void)applicationDidForeground {
    vc = [[ViewController alloc] init];
    self.window.rootViewController = vc;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    if (!geoFencer) { 
        geoFencer = [[GeoFencer alloc] init];
        [geoFencer applicationLaunchedForLocationUpdate];
    }
        
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self logPath]]) {
        [[NSFileManager defaultManager] createFileAtPath:[self logPath] contents:nil attributes:nil];
    }

    if (![[launchOptions allKeys] containsObject:UIApplicationLaunchOptionsLocationKey]) {
        [self applicationDidForeground];
    }
    return YES;
}

- (NSString *) logPath;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *filePath = [NSString stringWithFormat:@"%@/log.txt", [paths objectAtIndex:0]];
    return filePath;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    //[self append:@"Resign Active \n"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    //[self append:@"Enter BG \n"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    //[self append:@"Enter Foreground \n"];
    [self applicationDidForeground];
    [geoFencer applicationWillEnterForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //[self append:@"Became Active \n"];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self append:@"Terminated \n"];
}

- (void)append:(NSString *)string {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSString * log = [NSString stringWithFormat:@"%@	%@ App State: %d\n\n", [dateFormatter stringFromDate:[NSDate date]],string, [[UIApplication sharedApplication] applicationState]];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self logPath]];
    [fileHandle seekToEndOfFile];
    
    [fileHandle writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
    
    [fileHandle closeFile];
    
     [vc reload];
}

-(NSString*)logString;
{
    NSString * str = [NSString stringWithContentsOfFile:[self logPath] encoding:NSUTF8StringEncoding error:nil];
    return str;
}

@end
