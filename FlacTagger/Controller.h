//
//  Controller.h
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "MainWindowController.h"
#import "TagEditorWindowController.h"
#import "TagFromDiscogsWindowController.h"
#import "TrackNumberingWindowController.h"
#import "FileRenamingWindowController.h"

@interface Controller : NSObject<
MainWindowControllerDataSource,
MainWindowControllerDelegate,
TagEditorWindowControllerDelegate,
TagFromDiscogsWindowControllerDelegate,
TagEditorWindowControllerDataSource,
TagFromDiscogsWindowControllerDataSource,
TrackNumberingWindowControllerDelegate,
TrackNumberingWindowControllerDataSource,
FileRenamingWindowControllerDelegate,
FileRenamingWindowControllerDataSource>

-(void)applicationDidFinishedLaunching:(AppDelegate *)appDelegate;

@end
