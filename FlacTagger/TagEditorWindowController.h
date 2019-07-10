//
//  TagEditorWindowController.h
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TableViewWithActions.h"
#import "FileWithTags.h"
#import "EditIndividualValuesWindowController.h"

@interface TagEditorWindowControllerResult : NSObject

@property (readonly) FileWithTags * file;
@property (readonly) NSDictionary * editedTags;

-(instancetype)initWithFile:(FileWithTags*)file
                 editedTags:(NSDictionary*)editedTags;

@end

@class TagEditorWindowController;

@protocol TagEditorWindowControllerDataSource <NSObject>

-(NSArray *)filesForTagEditorWindowController:(TagEditorWindowController*)controller;

@end

@protocol TagEditorWindowControllerDelegate <NSObject>

-(void)tagEditorFinishedEditing:(TagEditorWindowController*)controller result:(NSArray*)result;
-(void)tagEditorCancelledEditing:(TagEditorWindowController*)controller;

@end

@interface TagEditorWindowController : NSWindowController<
NSTableViewDataSource,
TableViewWithActionsDelegate,
NSWindowDelegate,
EditIndividualValuesWindowControllerDataSource,
EditIndividualValuesWindowControllerDelegate>

@property (weak) id<TagEditorWindowControllerDelegate> delegate;
@property (weak) id<TagEditorWindowControllerDataSource> dataSource;

-(void)refresh;

@end
