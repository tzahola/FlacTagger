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

@implementation DiscogsReleaseSubtrack

- (instancetype)initWithPosition:(NSString *)position
                        duration:(NSTimeInterval)duration
                           title:(NSString *)title
                         artists:(NSArray<NSString *> *)artists {
    if (self = [super init]) {
        _position = [position copy];
        _duration = duration;
        _title = [title copy];
        _artists = [artists copy];
    }
    return self;
}

@end

@implementation DiscogsReleaseTrack

- (instancetype)initWithPosition:(NSString*)position
                       duration:(NSTimeInterval)duration
                          title:(NSString*)title
                        artists:(NSArray<NSString*>*)artists
                       subtracks:(NSArray<DiscogsReleaseSubtrack *> *)subtracks {
    if (self = [super init]) {
        _isHeading = NO;
        _position = [position copy];
        _duration = duration;
        _title = [title copy];
        _artists = [artists copy];
        _subtracks = [subtracks copy];
    }
    return self;
}

- (instancetype)initHeadingWithTitle:(NSString *)title {
    if (self = [super init]) {
        _isHeading = YES;
        _title = [title copy];
    }
    return self;
}

@end

@implementation DiscogsReleaseData

-(instancetype)initWithAlbumArtists:(NSArray *)albumArtists
                             genres:(NSArray<NSString *> *)genres
                             styles:(NSArray<NSString *> *)styles
                              album:(NSString *)album
                             tracks:(NSArray<DiscogsReleaseTrack *> *)tracks
                        releaseDate:(NSString *)releaseDate
                     catalogEntries:(NSArray<DiscogsReleaseCatalogEntry *> *)catalogEntries {
    if(self = [super init]){
        _albumArtists = [albumArtists copy];
        _genres = [genres copy];
        _styles = [styles copy];
        _album = [album copy];
        _tracks = [tracks copy];
        _releaseDate = [releaseDate copy];
        _catalogEntries = [catalogEntries copy];
    }
    return self;
}

@end

@implementation DiscogsReleaseDataLoader

- (NSTimeInterval)parseDuration:(NSString*)durationString {
    NSMutableArray<NSString*>* components = [[durationString componentsSeparatedByString:@":"].reverseObjectEnumerator.allObjects mutableCopy];
    while (components.count < 3) {
        [components addObject:@"0"];
    }
    return components[0].doubleValue + 60 * (components[1].doubleValue + 60 * components[2].doubleValue);
}

-(DiscogsReleaseData *)loadDataForReleaseId:(NSString *)releaseId error:(NSError *__autoreleasing *)error{
    NSURL * releaseURL = [NSURL URLWithString:[@"http://api.discogs.com/releases/" stringByAppendingString:releaseId]];
    
    NSData * discogsData = [NSData dataWithContentsOfURL:releaseURL options:NSDataReadingUncached error:error];
    
    NSDictionary * discogsDictionary = [NSJSONSerialization JSONObjectWithData:discogsData options:NSJSONReadingAllowFragments error:error];
    
    NSMutableArray * discogsTracks = [NSMutableArray new];
    for(NSDictionary * track in discogsDictionary[@"tracklist"]){
        NSString* type = track[@"type_"];
        if ([type isEqualToString:@"track"] || [type isEqualToString:@"index"]) {
            NSString * title = track[@"title"];
            NSMutableArray * artists = [NSMutableArray new];
            for(NSDictionary * artist in track[@"artists"]){
                [artists addObject:artist[@"name"]];
            }
            NSString* position = track[@"position"];
            NSTimeInterval duration = [self parseDuration:track[@"duration"]];
            
            NSMutableArray<DiscogsReleaseSubtrack*>* subtracks = nil;
            if (track[@"sub_tracks"]) {
                subtracks = [NSMutableArray new];
                for (NSDictionary* subtrack in track[@"sub_tracks"]) {
                    NSString* position = subtrack[@"position"];
                    NSMutableArray<NSString*>* artists = subtrack[@"artists"] ? [NSMutableArray new] : nil;
                    for(NSDictionary * artist in subtrack[@"artists"]){
                        [artists addObject:artist[@"name"]];
                    }
                    NSString* title = subtrack[@"title"];
                    NSTimeInterval duration = [self parseDuration:subtrack[@"duration"]];
                    [subtracks addObject:[[DiscogsReleaseSubtrack alloc] initWithPosition:position
                                                                                 duration:duration
                                                                                    title:title
                                                                                  artists:artists]];
                }
            }
            [discogsTracks addObject:[[DiscogsReleaseTrack alloc] initWithPosition:position
                                                                          duration:duration
                                                                             title:title
                                                                           artists:artists
                                                                         subtracks:subtracks]];
        } else if ([type isEqualToString:@"heading"]) {
            [discogsTracks addObject:[[DiscogsReleaseTrack alloc] initHeadingWithTitle:track[@"title"]]];
        }
    }
    
    NSMutableArray * albumArtists = discogsDictionary[@"artists"] ? [NSMutableArray new] : nil;
    for(NSDictionary * albumArtist in discogsDictionary[@"artists"]){
        [albumArtists addObject:albumArtist[@"name"]];
    }
    
    NSMutableArray * genres = discogsDictionary[@"genres"] ? [NSMutableArray new] : nil;
    for(NSString * genre in discogsDictionary[@"genres"]){
        [genres addObject:genre];
    }
    
    NSMutableArray * styles = discogsDictionary[@"styles"] ? [NSMutableArray new] : nil;
    for(NSString * style in discogsDictionary[@"styles"]){
        [styles addObject:style];
    }
    
    NSString * releaseDate = discogsDictionary[@"released"];
    NSString * album = discogsDictionary[@"title"];
    
    NSMutableArray* catalogEntries = discogsDictionary[@"labels"] ? [NSMutableArray new] : nil;
    for (NSDictionary* catalogEntry in discogsDictionary[@"labels"]) {
        [catalogEntries addObject:[[DiscogsReleaseCatalogEntry alloc] initWithLabel:catalogEntry[@"name"]
                                                                            catalog:catalogEntry[@"catno"]]];
    }
    
    return [[DiscogsReleaseData alloc] initWithAlbumArtists:albumArtists
                                                     genres:genres
                                                     styles:styles
                                                      album:album
                                                     tracks:discogsTracks
                                                releaseDate:releaseDate
                                             catalogEntries:catalogEntries];
}

@end
