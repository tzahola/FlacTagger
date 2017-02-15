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

@interface ChapterData : NSObject

@property (nonatomic, nonnull, readonly) NSString* title;
@property (nonatomic, readonly) NSTimeInterval startTime;

- (instancetype __nonnull)initWithTitle:(NSString* __nonnull)title startTime:(NSTimeInterval)startTime;

@end

@interface TrackData : NSObject

@property (nonatomic, nonnull, readonly) NSString* title;
@property (nonatomic, nonnull, readonly) NSArray<NSString*>* artists;
@property (nonatomic, nullable, readonly) NSArray<ChapterData*>* chapters;

- (instancetype __nonnull)initWithTitle:(NSString* __nonnull)title
                                 artist:(NSArray<NSString*>* __nonnull)artists
                               chapters:(NSArray<ChapterData*>* __nullable)chapters;

@end

@interface TrackGroupData : NSObject

@property (nonatomic, nullable, readonly) NSString* title;
@property (nonatomic, nonnull, readonly) NSArray<TrackData*>* tracks;

- (instancetype __nonnull)initWithTitle:(NSString* __nullable)title
                                 tracks:(NSArray<TrackData*>* __nonnull)tracks;

@end

@interface DiscData : NSObject

@property (nonatomic, nullable, readonly) NSString* title;
@property (nonatomic, nonnull, readonly) NSArray<TrackGroupData*>* trackGroups;

- (instancetype __nonnull)initWithTitle:(NSString* __nullable)title
                            trackGroups:(NSArray<TrackGroupData*>* __nonnull)trackGroups;

@end

@interface AlbumData : NSObject

@property (nonatomic, nonnull, readonly) NSArray<NSString*>* albumArtists;
@property (nonatomic, nonnull, readonly) NSArray<DiscData*>* discs;
@property (nonatomic, nonnull, readonly) NSArray<NSString*>* genres;
@property (nonatomic, nullable, readonly) NSArray<NSString*>* styles;

- (instancetype __nonnull)initWithAlbumArtists:(NSArray<NSString*>* __nonnull)albumArtists
                                         discs:(NSArray<DiscData*>* __nonnull)discs
                                        genres:(NSArray<NSString*>* __nonnull)genres
                                        styles:(NSArray<NSString*>* __nullable)styles;

@end

@interface TagFromDiscogsTableViewCell : NSTableCellView
@end

@interface DiscogsTaggingPair : NSObject

@property (nonatomic, nonnull, readonly) NSArray<FileWithTags*>* files;
@property (nonatomic, nonnull, readonly) AlbumData* data;

- (__nonnull instancetype)initWithFiles:(NSArray<FileWithTags*>* __nonnull)files
                                   data:(AlbumData* __nonnull)data;

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
