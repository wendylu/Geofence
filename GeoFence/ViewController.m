//
//  ViewControllerViewController.m
//  GeoFence
//
//  Created by Wendy Lu on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)reload {
    NSString *toDisplay = [(AppDelegate *)[[UIApplication sharedApplication] delegate] logString];
    int num = MIN(15000, [toDisplay length]);
    toDisplay = [toDisplay substringFromIndex:[toDisplay length] - num];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [textView setText:toDisplay];
        [self.view setNeedsDisplay];
    });
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
            }
    return self;
}   

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSString *toDisplay = [(AppDelegate *)[[UIApplication sharedApplication] delegate] logString];
    textView.text = toDisplay;
    [textView setNeedsDisplay];
}

- (void)viewDidUnload
{
    textView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
