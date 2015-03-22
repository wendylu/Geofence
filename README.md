Geofence
=============

An iOS app that tracks a user's location using only geofencing

## Get Started

```
git clone git@github.com:wendylu/Geofence.git
```

## Requirements

Geofence requires iOS 6.0 or higher and ARC

## About This Project

**Experiment**: Track a user's location using only geofencing and without the standard CoreLocation location services. I use a little bit of the significant-location change to wake the app up if it gets terminated. The goal is to compare the battery usage of this solution vs other location-tracking solutions.

**Proposed Scheme:**

1. On Launch
   a. create location manager with distanceFilter = 100 and desiredAccuracy= kCLLocationAccuracyBestForNavigation
   b. restart background task
   b. turnOnMonitoringFor:45

2. turnOnMonitoringFor:(float) pollingTime
   a. Save currently monitored region in origRegion
   b. startUpdatingLocation
   c. after pollingTime seconds
      i. stopUpdatingLocation 
      	 ii. if currently monitored region equals origRegion (we failed to get a new location point), increase current fence radius by 32000 (max distance traveled in 10 min)
	     iii. kill background task

3. On each update point we receive:
   a. restart background task
   b. check that it's not a old cached point (timestamp not more than 5 seconds old)
   c. if point.horizontalAccuracy <= 100
      i. stopUpdatingLocation (we obtained an accurate enough point)
      d. Create a fence with radius: MAX(newLocation.horizontalAccuracy+450, newLocation.horizontalAccuracy*2) and accuracy:kCLLocationAccuracyNearestTenMeters
      e. Stop monitoring for old regions (should only be one, but check locationmanager.monitoredRegions just in case)

4. On exiting a fence (didExitRegion:(CLRegion *)region)
   a. restart background task
   b. If more than 30 second of background time remaining
      i. wait until within 75 seconds of bg time expiration to call turnOnMonitoringFor
      c. If 30 seconds or less background time remaining
      	 ii. no time to start location updates, we are within 30 sec of running out of bg time. change radius of fence we just exited to MAX(2*old radius, 5km)

5. On Foreground
   a. restart background task
   b. turnOnMonitoringFor:45

6. On Termination (force quit or quit by OS)
   a. If we are not currently running in the background (suspended state). This means we have a fence set up and are inside of it because at each fence  exit, before bg time expires, we should have created a fence around our current location
      i. don't need to do anything, will be relaunched on fence exit (goto step 1). Good because we don't get an applicationWillTerminate notify when in suspended state
      b. If currently running in the background, we may or may not have a fence set up around our current location. 
      	 i. start SLC?? On SLC or fence exit, will be relaunched (goto step 1)

TODO: handle fail to get location point on launch
