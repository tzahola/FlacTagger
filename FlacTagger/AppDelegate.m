//
//  AppDelegate.m
//  FlacTagger
//
//  Created by Tamás Zahola on 15/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "AppDelegate.h"
#import "Controller.h"

@interface AppDelegate ()

@property Controller * controller;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.controller = [Controller new];
    [self.controller applicationDidFinishedLaunching:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
