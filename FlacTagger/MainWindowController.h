//
//  MainWindowController.h
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileWithTags.h"
#import "TableViewWithActions.h"

@class MainWindowController;

@protocol MainWindowControllerDataSource <NSObject>

-(NSArray *)filesForMainWindowController:(MainWindowController *)controller;

@end

@protocol MainWindowControllerDelegate <NSObject>

-(void)mainWindowController:(MainWindowController *)controller didDropFileURLs:(NSArray<NSURL*>*)fileURLs;

-(void)mainWindowController:(MainWindowController *)controller deleteFiles:(NSArray *)files;
-(void)mainWindowController:(MainWindowController *)controller editFiles:(NSArray*)files;
-(void)mainWindowController:(MainWindowController *)controller tagFilesFromDiscogs:(NSArray*)files;
-(void)mainWindowController:(MainWindowController *)controller numberFiles:(NSArray*)files;
-(void)mainWindowController:(MainWindowController *)controller renameFiles:(NSArray*)files;

@end

@interface MainWindowController : NSWindowController<NSTableViewDataSource, TableViewWithActionsDelegate>

@property (weak) id<MainWindowControllerDelegate> delegate;
@property (weak) id<MainWindowControllerDataSource> dataSource;

-(void)refresh;

@end
