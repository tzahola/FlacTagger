//
//  DiscogsReleaseData.h
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DiscogsReleaseCatalogEntry : NSObject

@property (readonly) NSString * label;
@property (readonly) NSString * catalog;

- (instancetype)initWithLabel:(NSString*)label
                      catalog:(NSString*)catalog;

@end

@interface DiscogsReleaseTrack : NSObject

@property (readonly) NSString* position;
@property (readonly) NSString * title;
@property (readonly) NSArray * artists;

-(instancetype)initWithPosition:(NSString*)position
                          title:(NSString *)title
                        artists:(NSArray *)artists;

@end

@interface DiscogsReleaseData : NSObject

@property (readonly) NSArray * albumArtists;
@property (readonly) NSArray * genres;
@property (readonly) NSString * album;
@property (readonly) NSArray * tracks;
@property (readonly) NSString * releaseDate;
@property (readonly) NSArray* catalogEntries;

-(instancetype)initWithAlbumArtists:(NSArray *)albumArtists
                             genres:(NSArray *)genres
                              album:(NSString *)album
                             tracks:(NSArray *)tracks
                        releaseDate:(NSString *)releaseDate
                     catalogEntries:(NSArray *)catalogEntries;

@end

@interface DiscogsReleaseDataLoader : NSObject

-(DiscogsReleaseData*)loadDataForReleaseId:(NSString*)releaseId error:(NSError * __autoreleasing *)error;

@end
