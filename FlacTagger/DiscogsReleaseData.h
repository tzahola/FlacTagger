//
//  DiscogsReleaseData.h
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DiscogsReleaseTrack : NSObject

@property(readonly) NSString * title;
@property(readonly) NSArray * artists;

-(instancetype)initWithTitle:(NSString *)title
                     artists:(NSArray *)artists;

@end

@interface DiscogsReleaseData : NSObject

@property(readonly) NSArray * albumArtists;
@property(readonly) NSArray * genres;
@property(readonly) NSString * album;
@property(readonly) NSArray * tracks;
@property(readonly) NSString * releaseDate;

-(instancetype)initWithAlbumArtists:(NSArray *)albumArtists
                             genres:(NSArray *)genres
                              album:(NSString *)album
                             tracks:(NSArray *)tracks
                        releaseDate:(NSString *)releaseDate;

@end

@interface DiscogsReleaseDataLoader : NSObject

-(DiscogsReleaseData*)loadDataForReleaseId:(NSString*)releaseId error:(NSError * __autoreleasing *)error;

@end