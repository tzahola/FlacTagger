//
//  DiscogsReleaseData.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "DiscogsReleaseData.h"

@implementation DiscogsReleaseTrack

-(instancetype)initWithTitle:(NSString *)title artists:(NSArray *)artists{
    if(self = [super init]){
        _title = title;
        _artists = artists;
    }
    return self;
}

@end

@implementation DiscogsReleaseData

-(instancetype)initWithAlbumArtists:(NSArray *)albumArtists
                             genres:(NSArray *)genres
                              album:(NSString *)album
                             tracks:(NSArray *)tracks
                        releaseDate:(NSString *)releaseDate{
    if(self = [super init]){
        _album = album;
        _albumArtists = albumArtists;
        _genres = genres;
        _tracks = tracks;
        _releaseDate = releaseDate;
    }
    return self;
}

@end

@implementation DiscogsReleaseDataLoader

-(DiscogsReleaseData *)loadDataForReleaseId:(NSString *)releaseId error:(NSError *__autoreleasing *)error{
    NSURL * releaseURL = [NSURL URLWithString:[@"http://api.discogs.com/releases/" stringByAppendingString:releaseId]];
    
    NSData * discogsData = [NSData dataWithContentsOfURL:releaseURL options:NSDataReadingUncached error:error];
    
    
    NSDictionary * discogsDictionary = [NSJSONSerialization JSONObjectWithData:discogsData options:NSJSONReadingAllowFragments error:error];
    
    NSMutableArray * discogsTracks = [NSMutableArray new];
    for(NSDictionary * track in discogsDictionary[@"tracklist"]){
        NSString * title = track[@"title"];
        NSMutableArray * artists = [NSMutableArray new];
        for(NSDictionary * artist in track[@"artists"]){
            [artists addObject:artist[@"name"]];
        }
        [discogsTracks addObject:[[DiscogsReleaseTrack alloc] initWithTitle:title artists:artists]];
    }
    
    NSMutableArray * albumArtists = [NSMutableArray new];
    for(NSDictionary * albumArtist in discogsDictionary[@"artists"]){
        [albumArtists addObject:albumArtist[@"name"]];
    }
    
    NSMutableArray * genres = [NSMutableArray new];
    for(NSString * genre in discogsDictionary[@"genres"]){
        [genres addObject:genre];
    }
    
    NSString * releaseDate = discogsDictionary[@"released"];
    NSString * album = discogsDictionary[@"title"];
    
    return [[DiscogsReleaseData alloc] initWithAlbumArtists:albumArtists genres:genres album:album tracks:discogsTracks releaseDate:releaseDate];
}

@end