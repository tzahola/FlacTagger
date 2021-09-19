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
@property (readonly) NSString * artist;

-(instancetype)initWithPosition:(NSString*)position
                          title:(NSString *)title
                         artist:(NSString *)artist;

@end

@interface DiscogsReleaseData : NSObject

@property (readonly) NSString * albumArtist;
@property (readonly) NSArray * genres;
@property (readonly) NSString * album;
@property (readonly) NSArray * tracks;
@property (readonly) NSString * releaseDate;
@property (readonly) NSString * originalDate;
@property (readonly) NSArray* catalogEntries;

-(instancetype)initWithAlbumArtist:(NSString *)albumArtist
                            genres:(NSArray *)genres
                             album:(NSString *)album
                            tracks:(NSArray *)tracks
                       releaseDate:(NSString *)releaseDate
                      originalDate:(NSString *)originalDate
                    catalogEntries:(NSArray *)catalogEntries;

@end

@interface DiscogsReleaseDataLoader : NSObject

-(DiscogsReleaseData*)loadDataForReleaseId:(NSString*)releaseId error:(NSError * __autoreleasing *)error;

@end
