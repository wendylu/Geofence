//
//  GeoFencer.h
//  GeoFence
//
//  Created by Wendy Lu on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MyCircle.h"

@interface GeoFencer : NSObject <CLLocationManagerDelegate>

- (void) applicationLaunchedForLocationUpdate;
- (void) applicationWillEnterForeground;

@end
