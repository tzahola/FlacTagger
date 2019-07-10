//
//  DiscogsReleaseData.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "DiscogsReleaseData.h"

@implementation DiscogsReleaseCatalogEntry

- (instancetype)initWithLabel:(NSString *)label catalog:(NSString *)catalog {
    if (self = [super init]) {
        _label = [label copy];
        _catalog = [catalog copy];
    }
    return self;
}

@end

@implementation DiscogsReleaseTrack

-(instancetype)initWithPosition:(NSString *)position title:(NSString *)title artists:(NSArray *)artists {
    if (self = [super init]) {
        _position = [position copy];
        _title = [title copy];
        _artists = [artists copy];
    }
    return self;
}

@end

@implementation DiscogsReleaseData

-(instancetype)initWithAlbumArtists:(NSArray *)albumArtists
                             genres:(NSArray *)genres
                              album:(NSString *)album
                             tracks:(NSArray *)tracks
                        releaseDate:(NSString *)releaseDate
                     catalogEntries:(NSArray *)catalogEntries {
    if (self = [super init]) {
        _album = [album copy];
        _albumArtists = [albumArtists copy];
        _genres = [genres copy];
        _tracks = [tracks copy];
        _releaseDate = [releaseDate copy];
        _catalogEntries = [catalogEntries copy];
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
    NSArray* discogsTracklist = [((NSArray<NSDictionary*>*)discogsDictionary[@"tracklist"])
         sortedArrayUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull obj1, NSDictionary*  _Nonnull obj2) {
            return [obj1[@"position"] compare:obj2[@"position"] options:NSNumericSearch];
        }];
    for (NSDictionary * track in discogsTracklist) {
        NSString* type = track[@"type_"];
        if ([type isEqualToString:@"track"]) {
            NSString * title = track[@"title"];
            NSMutableArray * artists = [NSMutableArray new];
            for (NSDictionary * artist in track[@"artists"]) {
                [artists addObject:artist[@"name"]];
            }
            NSString* position = track[@"position"];
            [discogsTracks addObject:[[DiscogsReleaseTrack alloc] initWithPosition:position title:title artists:artists]];
        } else if ([type isEqualToString:@"index"]) {
            NSMutableArray* positions = [NSMutableArray new];
            NSMutableArray* artists = [NSMutableArray new];
            
            if ([track[@"position"] length] > 0) {
                [positions addObject:track[@"position"]];
            }
            for (NSDictionary * artist in track[@"artists"]) {
                [artists addObject:artist[@"name"]];
            }
            
            NSMutableArray* subtitles = [NSMutableArray new];
            for (NSDictionary* subtrack in track[@"sub_tracks"]) {
                if ([subtrack[@"position"] length] > 0) {
                    [positions addObject:subtrack[@"position"]];
                }
                for (NSDictionary * artist in subtrack[@"artists"]) {
                    [artists addObject:artist[@"name"]];
                }
                if ([subtrack[@"title"] length] > 0) {
                    [subtitles addObject:subtrack[@"title"]];
                }
            }
            
            NSString* substitlesJoined = [subtitles componentsJoinedByString:@", "];
            NSString* title = [track[@"title"] length] > 0 ?
                [NSString stringWithFormat:@"%@ (%@)", track[@"title"], substitlesJoined] :
                substitlesJoined;
            
            [discogsTracks addObject:[[DiscogsReleaseTrack alloc] initWithPosition:[positions componentsJoinedByString:@", "]
                                                                             title:title
                                                                           artists:artists]];
        }
    }
    
    NSMutableArray * albumArtists = [NSMutableArray new];
    for (NSDictionary * albumArtist in discogsDictionary[@"artists"]) {
        [albumArtists addObject:albumArtist[@"name"]];
    }
    
    NSMutableArray * genres = [NSMutableArray new];
    for (NSString * genre in discogsDictionary[@"genres"]) {
        [genres addObject:genre];
    }
    
    NSString * releaseDate = discogsDictionary[@"released"];
    NSString * album = discogsDictionary[@"title"];
    
    NSMutableArray* catalogEntries = [NSMutableArray new];
    for (NSDictionary* catalogEntry in discogsDictionary[@"labels"]) {
        [catalogEntries addObject:[[DiscogsReleaseCatalogEntry alloc] initWithLabel:catalogEntry[@"name"]
                                                                            catalog:catalogEntry[@"catno"]]];
    }
    
    return [[DiscogsReleaseData alloc] initWithAlbumArtists:albumArtists genres:genres album:album tracks:discogsTracks releaseDate:releaseDate catalogEntries:catalogEntries];
}

@end
