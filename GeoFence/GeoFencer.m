//
//  GeoFencer.m
//  GeoFence
//
//  Created by Wendy Lu on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeoFencer.h"
#import "AppDelegate.h"

#define SAFETY_FACTOR 20.0
#define POLLING_BUFFER 30.0
#define DEFAULT_BG_TIME 600.0
#define MAX_DISTANCE_IN_TEN_MIN 32000

@implementation GeoFencer {
    CLLocationManager *_locationManager;
    CLLocationManager *_slcLocationManager;
    UIBackgroundTaskIdentifier _bgTask;
    CLRegion *_curRegion;
    int _regionCount;
    dispatch_queue_t _setRegionQueue;
    float _safetyFactor, _pollingBuffer;
    float _pollingDuration;
    int _count;
}

#pragma mark -
#pragma mark Public Interface

- (void) applicationLaunchedForLocationUpdate {
    //_locationManager = nil;
    if (nil == _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter = 100;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        _locationManager.delegate = self;
        _curRegion = nil;
        _regionCount = _locationManager.monitoredRegions.count;
    }
    
    if (_setRegionQueue == nil) {
        _setRegionQueue = dispatch_queue_create("com.example.MyQueue", NULL);
    }
    
    [self reUpBGTask];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self turnOnMonitoringFor:_pollingDuration];
    });
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:@"Launched"];
}

- (id)init {
    self = [super init];
    if (self) {
        _pollingDuration = 45;
        _pollingBuffer = POLLING_BUFFER;
        _safetyFactor = SAFETY_FACTOR;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

//If we've we've exited the last fence, but may not have made the new fence yet, start SLC. We don't know where we are and don't have time to poll and set a new fence.
- (void) applicationWillTerminate {
    [_locationManager startMonitoringSignificantLocationChanges];
}

- (void) applicationWillEnterForeground {
    NSString *log = @"";
    for (CLRegion *r in _locationManager.monitoredRegions) {
        log = [NSString stringWithFormat:@"Cur Fence: %@ Coord: %f, %f Rad: %f ", r.identifier, r.center.latitude, r.center.longitude, r.radius];
    }
    log = [log stringByAppendingString:@"\n"];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:log];
    
    //re-fence in case lost
    [self reUpBGTask];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self turnOnMonitoringFor:_pollingDuration];
    });
}

//origRegion is the region that was exited to trigger the dispatching of this method
- (void) turnOnMonitoringFor:(float) seconds {
    CLRegion *origRegion = _locationManager.monitoredRegions.anyObject;
    [_locationManager startUpdatingLocation];
    double delayInSeconds = seconds;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [_locationManager stopUpdatingLocation];
        
        //check if we are still monitoring the same region, aka we didn't get a location point. Make the radius of the current region LARGE
        for (CLRegion *r in _locationManager.monitoredRegions) {
            if ([origRegion.identifier isEqualToString:r.identifier]) { 
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:@"Failed to get location update"];
                MyCircle *myCircle = [[MyCircle alloc] init];
                myCircle.coordinate = r.center;
                myCircle.radius = MAX_DISTANCE_IN_TEN_MIN + r.radius;
                NSString *ident = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
                [self registerRegionWithCircularOverlay:myCircle andIdentifier:ident];
            }
        }
        
        [self paranoidKillBGTask];
    });
    [self paranoidKillBGTask];
}

- (void) paranoidKillBGTask {
    NSString *log = [NSString stringWithFormat:@"Call ParanoidKill BGTime: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:log];
    if ([[UIApplication sharedApplication] backgroundTimeRemaining] <= _pollingBuffer) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:@"Performed paranoid Kill"];
        if (_bgTask != UIBackgroundTaskInvalid) {
            [_locationManager stopUpdatingLocation];
            
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
        }
    }
}

- (BOOL)registerRegionWithCircularOverlay:(MyCircle*)overlay andIdentifier:(NSString*)identifier
{
    // Do not create regions if support is unavailable or disabled.
    if ( ![CLLocationManager regionMonitoringAvailable] ||
        ![CLLocationManager regionMonitoringEnabled] )
        return NO;
    
    // If the radius is too large, registration fails automatically,
    // so clamp the radius to the max value.
    CLLocationDegrees radius = overlay.radius;
    if (radius > _locationManager.maximumRegionMonitoringDistance)
        radius = _locationManager.maximumRegionMonitoringDistance;
    
    // Create the region and start monitoring it.
    CLRegion* region = [[CLRegion alloc] initCircularRegionWithCenter:overlay.coordinate
                                                               radius:overlay.radius identifier:identifier];
    [_locationManager startMonitoringForRegion:region
                              desiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    _regionCount++;
        
    //stop monitoring for old regions (should only be one, but check monitoredRegions just in case)
    for (CLRegion *reg in _locationManager.monitoredRegions) {
        if (![reg.identifier isEqualToString:region.identifier]) {
            [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:[NSString stringWithFormat:@"Stop Monitoring for region %@",reg.identifier]];
            [_locationManager stopMonitoringForRegion:reg];
            _regionCount--;
        }
    }
    
    //save this as our current region
    _curRegion = region;
    
    NSString *log = [NSString stringWithFormat:@"Monitoring fence at coordinate: %f, %f Name: %@\n Region Count: %d ", _curRegion.center.latitude, _curRegion.center.longitude, _curRegion.identifier, _locationManager.monitoredRegions.count];
    NSString *allRegionNames = @"";
    for (CLRegion *monitored in _locationManager.monitoredRegions) {
        allRegionNames = [allRegionNames stringByAppendingString:monitored.identifier];
    }
    log = [log stringByAppendingString:[allRegionNames stringByAppendingString:@"\n"]];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:log];

    
    [self notif:@"New Fence!"];

    return YES;
}

- (void) reUpBGTask {
    UIBackgroundTaskIdentifier tempbgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (_bgTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
        }
        _bgTask = UIBackgroundTaskInvalid;
    }];
    
    if (_bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }
    _bgTask = tempbgTask;
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    [self reUpBGTask];
    dispatch_async(_setRegionQueue, ^{
        //check that it's not a old cached point
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        if (locationAge > 5.0) return;
        
        //log this point
        NSString *log = [NSString stringWithFormat:@"Got point: %f, %f Accuracy: %f\n", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:log];
        
        // This is the polling case
        if (manager==_locationManager) {  //accurate update coming from poll event 
            if (newLocation.horizontalAccuracy <= 100.0) {
                [_locationManager stopUpdatingLocation];
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:@"Stop Updating\n"];
            }
            
            MyCircle *myCircle = [[MyCircle alloc] init];
            myCircle.coordinate = newLocation.coordinate;
            myCircle.radius = MAX(newLocation.horizontalAccuracy + 450, newLocation.horizontalAccuracy * 2);
            NSString *ident = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]; 
            
            [self registerRegionWithCircularOverlay:myCircle andIdentifier:ident];
            
        }
    });
    
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self reUpBGTask];
    if (manager == _locationManager) {
        NSString *log = [NSString stringWithFormat:@"Did Enter: %@\n", region.identifier];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:log]; 
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self reUpBGTask]; 
    if (manager == _locationManager) {
        NSString *log = [NSString stringWithFormat:@"Did Exit: %@ BGTime: %f\n", region.identifier, [[UIApplication sharedApplication] backgroundTimeRemaining]];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] append:log];    
        
        [self notif:@"Exited"];
        
        NSTimeInterval backgroundTimeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
        if (backgroundTimeRemaining > 10000) {  // Application in foreground
            backgroundTimeRemaining = DEFAULT_BG_TIME;
        }
        double available_polling_duration = backgroundTimeRemaining - _pollingBuffer;
        if (available_polling_duration > 0.0) {
            //wait until near end bg time, poll to create fence
            double this_poll_duration = MIN(available_polling_duration, _pollingDuration);
            double this_delay_time = backgroundTimeRemaining - _pollingBuffer - this_poll_duration; // time to wait before asking for location
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, this_delay_time * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [self turnOnMonitoringFor:this_poll_duration];
            });
        } else {
            //no time to create fence, we are within 30 sec of running out of bg time. increase radius of fence we just exited by double
            [self doubleRadiusOfCurrentRegion];
        }
    }
}

- (void) doubleRadiusOfCurrentRegion {
    dispatch_async(_setRegionQueue, ^{
        for (CLRegion *reg in _locationManager.monitoredRegions) {
            MyCircle *myCircle = [[MyCircle alloc] init];
            myCircle.coordinate = reg.center;
            myCircle.radius = MAX(reg.radius * 2, 5000);
            NSString *ident = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
            [self registerRegionWithCircularOverlay:myCircle andIdentifier:ident];
        }
    });
}

- (void) notif:(NSString *)string
{
    NSDate *itemDate = [NSDate date];
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
        return;
    localNotif.fireDate = [itemDate dateByAddingTimeInterval:3];
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    
    localNotif.alertBody = [NSString stringWithFormat:NSLocalizedString(string, nil)];
    localNotif.alertAction = NSLocalizedString(@"View Details", nil);
    
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = 1;
    
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

@end
