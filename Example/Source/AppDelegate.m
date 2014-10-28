//
//  AppDelegate.m
//  SplitView
//
//  Created by Alexander Cohen on 2014-10-23.
//  Copyright (c) 2014 BedroomCode. All rights reserved.
//

#import "AppDelegate.h"
#import "NFSplitViewController.h"
#import "TestViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic,strong) NFSplitViewController* splitViewController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSView* contentView = self.window.contentView;
    
    self.splitViewController = [[NFSplitViewController alloc] init];
    self.splitViewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.splitViewController.view.frame = contentView.bounds;
    self.splitViewController.vertical = NO;
    [contentView addSubview:self.splitViewController.view];
    
    TestViewController* vc1 = [[TestViewController alloc] init];
    vc1.backgroundColor = [NSColor colorWithDeviceRed:246.0/255.0 green:246.0/255.0 blue:246.0/255.0 alpha:1];
    vc1.name = @"Source";
    vc1.textField.hidden = YES;
    [self.splitViewController addChildViewController:vc1];
    
    NFSplitViewController* sp2 = [[NFSplitViewController alloc] init];
    sp2.vertical = YES;
    
    TestViewController* vc2 = [[TestViewController alloc] init];
    vc2.backgroundColor = [NSColor whiteColor];
    vc2.name = @"Detail Top";
    [sp2 addChildViewController:vc2];
    
    TestViewController* vc3 = [[TestViewController alloc] init];
    vc3.backgroundColor = [NSColor whiteColor];
    vc3.name = @"Detail Bottom";
    [sp2 addChildViewController:vc3];
    
    [self.splitViewController addChildViewController:sp2];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)collapseSplitView:(id)sender
{
    [self.splitViewController collapseViewControllerAtIndex:0 animated:YES];
}

- (IBAction)toggleOrientation:(id)sender
{
    self.splitViewController.vertical = !self.splitViewController.vertical;
}

@end
