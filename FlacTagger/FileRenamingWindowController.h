//
//  FileRenamingWindowController.h
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileWithTags.h"

@interface FileRenaming : NSObject

@property (readonly) FileWithTags * file;
@property (readonly,getter = nnewFileName) NSString * newFileName;

-(instancetype)initWithFile:(FileWithTags*)file
                newFileName:(NSString*)newFileName;

@end

@class FileRenamingWindowController;

@protocol FileRenamingWindowControllerDataSource <NSObject>

-(NSArray*)filesForFileRenamingWindowController:(FileRenamingWindowController*)controller;

@end

@protocol FileRenamingWindowControllerDelegate <NSObject>

-(void)fileRenamingWindowControllerCancel:(FileRenamingWindowController*)controller;
-(void)fileRenamingWindowController:(FileRenamingWindowController*)controller renameFiles:(NSArray*)renamings;

@end

@interface FileRenamingWindowController : NSWindowController<NSTableViewDataSource,NSTableViewDelegate>

@property (weak) id<FileRenamingWindowControllerDataSource> dataSource;
@property (weak) id<FileRenamingWindowControllerDelegate> delegate;

-(void)refresh;

@end
