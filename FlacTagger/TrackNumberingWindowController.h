//
//  TrackNumberingWindowController.h
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileWithTags.h"

@interface TrackNumberingResult : NSObject

@property (readonly) FileWithTags * file;
@property (readonly) NSInteger discNumber;
@property (readonly) NSInteger trackNumber;
@property (readonly) NSInteger discTotal;
@property (readonly) NSInteger trackTotal;

-(instancetype)initWithFile:(FileWithTags*)file
                 discNumber:(NSInteger)discNumber
                trackNumber:(NSInteger)trackNumber
                 discTotal:(NSInteger)discTotal
                trackTotal:(NSInteger)trackTotal;

@end

@class TrackNumberingWindowController;

@protocol TrackNumberingWindowControllerDelegate <NSObject>

-(void)trackNumberingWindowControllerDidCancel:(TrackNumberingWindowController*)controller;
-(void)trackNumberingWindowController:(TrackNumberingWindowController*)controller
                  finishedWithResults:(NSArray*)trackNumberingResults;

@end

@protocol TrackNumberingWindowControllerDataSource <NSObject>

-(NSArray*)filesForTrackNumberingWindowController:(TrackNumberingWindowController*)controller;

@end

@interface TrackNumberingWindowController : NSWindowController<NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate>

@property (weak) id<TrackNumberingWindowControllerDataSource> dataSource;
@property (weak) id<TrackNumberingWindowControllerDelegate> delegate;

-(void)refresh;

@end
