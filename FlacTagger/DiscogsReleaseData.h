//
//  DiscogsReleaseData.h
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DiscogsReleaseCatalogEntry : NSObject

@property(nonatomic, copy) NSString* label;
@property(nonatomic, copy) NSString* catalog;

- (instancetype)initWithLabel:(NSString*)label
                      catalog:(NSString*)catalog;

@end

@interface DiscogsReleaseSubtrack : NSObject

@property(nonatomic, copy) NSString* position;
@property(nonatomic) NSTimeInterval duration;
@property(nonatomic, copy) NSString* title;
@property(nonatomic, copy) NSArray<NSString*>* artists;

- (instancetype)initWithPosition:(NSString*)position
                        duration:(NSTimeInterval)duration
                           title:(NSString*)title
                         artists:(NSArray<NSString*>*)artists;

@end

@interface DiscogsReleaseTrack : NSObject

@property(nonatomic) BOOL isHeading;
@property(nonatomic, copy) NSString* position;
@property(nonatomic) NSTimeInterval duration;
@property(nonatomic, copy) NSString* title;
@property(nonatomic, copy) NSArray<NSString*>* artists;
@property(nonatomic, copy) NSArray<DiscogsReleaseSubtrack*>* subtracks;

- (instancetype)initWithPosition:(NSString*)position
                        duration:(NSTimeInterval)duration
                           title:(NSString*)title
                         artists:(NSArray<NSString*>*)artists
                       subtracks:(NSArray<DiscogsReleaseSubtrack*>*)subtracks;

- (instancetype)initHeadingWithTitle:(NSString*)title;

@end

@interface DiscogsReleaseData : NSObject

@property(nonatomic, copy) NSArray<NSString*>* albumArtists;
@property(nonatomic, copy) NSArray<NSString*>* genres;
@property(nonatomic, copy) NSArray<NSString*>* styles;
@property(nonatomic, copy) NSString* album;
@property(nonatomic, copy) NSArray<DiscogsReleaseTrack*>* tracks;
@property(nonatomic, copy) NSString* releaseDate;
@property(nonatomic, copy) NSArray<DiscogsReleaseCatalogEntry*>* catalogEntries;

- (instancetype)initWithAlbumArtists:(NSArray<NSString*>*)albumArtists
                              genres:(NSArray<NSString*>*)genres
                              styles:(NSArray<NSString*>*)styles
                               album:(NSString*)album
                              tracks:(NSArray<DiscogsReleaseTrack*>*)tracks
                         releaseDate:(NSString*)releaseDate
                      catalogEntries:(NSArray<DiscogsReleaseCatalogEntry*>*)catalogEntries;

@end

@interface DiscogsReleaseDataLoader : NSObject

- (DiscogsReleaseData*)loadDataForReleaseId:(NSString*)releaseId
                                      error:(NSError* __autoreleasing*)error;

@end
