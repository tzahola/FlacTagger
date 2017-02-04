//
//  TagFromDiscogsWindowController.h
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileWithTags.h"
#import "DiscogsReleaseData.h"

@interface TagFromDiscogsTableViewCell : NSTableCellView
@end

@interface DiscogsTaggingPair : NSObject

@property(readonly) FileWithTags * file;
@property(readonly) DiscogsReleaseTrack * discogsData;

-(instancetype)initWithFile:(FileWithTags*)file
                discogsData:(DiscogsReleaseTrack*)discogsData;

@end

@class TagFromDiscogsWindowController;

@protocol TagFromDiscogsWindowControllerDataSource <NSObject>

-(DiscogsReleaseData *)tagFromDiscogsWindowController:(TagFromDiscogsWindowController*)controller
                                  fetchDataForRelease:(NSString*)releaseID;

-(NSArray *)tagFromDiscogsWindowControllerFiles:(TagFromDiscogsWindowController*)controller;

@end

@protocol TagFromDiscogsWindowControllerDelegate <NSObject>

-(void)tagFromDiscogsWindowControllerDidCancel:(TagFromDiscogsWindowController *)controller;
-(void)tagFromDiscogsWindowController:(TagFromDiscogsWindowController*)controller
                    finishedWithPairs:(NSArray*)pairings
                         catalogEntry:(DiscogsReleaseCatalogEntry*)catalogEntry;

@end

@interface TagFromDiscogsWindowController : NSWindowController<NSWindowDelegate,NSTableViewDataSource,NSTableViewDelegate>

@property(weak) id<TagFromDiscogsWindowControllerDelegate> delegate;
@property(weak) id<TagFromDiscogsWindowControllerDataSource> dataSource;

-(void)startWizard;

@end
