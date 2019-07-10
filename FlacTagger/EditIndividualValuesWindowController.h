//
//  EditIndividualValuesWindowController.h
//  FlacTagger
//
//  Created by Tamás Zahola on 23/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileWithTags.h"

@class EditIndividualValuesWindowController;

@interface FileWithIndividualTagValue : NSObject

@property (readonly) FileWithTags * file;
@property (readonly) NSString * tagValue;

-(instancetype)initWithFile:(FileWithTags*)file
                   tagValue:(NSString*)tagValue;

@end

@protocol EditIndividualValuesWindowControllerDataSource <NSObject>

-(NSArray *)filesWithTagValueForIndividualTagValueEditor:(EditIndividualValuesWindowController*)controller;

@end

@protocol EditIndividualValuesWindowControllerDelegate <NSObject>

-(void)individualTagValueEditorFinished:(EditIndividualValuesWindowController *)controller
                             withResult:(NSArray*)result;
-(void)individualTagValueEditorCancel:(EditIndividualValuesWindowController *)controller;

@end

@interface EditIndividualValuesWindowController : NSWindowController<NSTableViewDataSource,NSTableViewDelegate>

@property (weak) id<EditIndividualValuesWindowControllerDelegate> delegate;
@property (weak) id<EditIndividualValuesWindowControllerDataSource> dataSource;

-(void)refresh;

@end
