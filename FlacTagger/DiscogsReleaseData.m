//
//  DiscogsReleaseData.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "DiscogsReleaseData.h"

@interface NSString (NilIfEmpty)
@property (nonatomic, nullable, readonly) NSString* nilIfEmpty;
@end

@implementation NSString (NilIfEmpty)

- (NSString *)nilIfEmpty {
    return self.length == 0 ? nil : self;
}

@end

@implementation DiscogsReleaseCatalogEntry

- (instancetype)initWithLabel:(NSString *)label
                      catalog:(NSString *)catalog {
    NSParameterAssert(label.length > 0);
    NSParameterAssert(catalog.length > 0);

    if (self = [super init]) {
        _label = [label copy];
        _catalog = [catalog copy];
    }
    return self;
}

@end

@implementation DiscogsReleaseTrack

-(instancetype)initWithPosition:(NSString *)position
                          title:(NSString *)title
                         artist:(NSString *)artist {
    NSParameterAssert(position.length > 0);
    NSParameterAssert(title.length > 0);
    NSParameterAssert(artist == nil || artist.length > 0);

    if (self = [super init]) {
        _position = [position copy];
        _title = [title copy];
        _artist = [artist copy];
    }
    return self;
}

@end

@implementation DiscogsReleaseData

-(instancetype)initWithAlbumArtist:(NSString *)albumArtist
                            genres:(NSArray *)genres
                             album:(NSString *)album
                            tracks:(NSArray *)tracks
                       releaseDate:(NSString *)releaseDate
                      originalDate:(NSString *)originalDate
                    catalogEntries:(NSArray *)catalogEntries {
    NSParameterAssert(albumArtist.length > 0);
    NSParameterAssert(genres.count > 0);
    NSParameterAssert(album.length > 0);
    NSParameterAssert(tracks.count > 0);
    NSParameterAssert(releaseDate == nil || releaseDate.length > 0);
    NSParameterAssert(originalDate == nil || originalDate.length > 0);
    NSParameterAssert(catalogEntries.count > 0);

    if (self = [super init]) {
        _album = [album copy];
        _albumArtist = [albumArtist copy];
        _genres = [genres copy];
        _tracks = [tracks copy];
        _releaseDate = [releaseDate copy];
        _originalDate = [originalDate copy];
        _catalogEntries = [catalogEntries copy];
    }
    return self;
}

@end

@implementation DiscogsReleaseDataLoader

-(DiscogsReleaseData *)loadDataForReleaseId:(NSString *)releaseId error:(NSError *__autoreleasing *)error{
    NSURL * releaseURL = [NSURL URLWithString:[@"http://api.discogs.com/releases/" stringByAppendingString:releaseId]];

    NSData * data = [NSData dataWithContentsOfURL:releaseURL options:NSDataReadingUncached error:error];
    if (data == nil) {
        return nil;
    }

    NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
    if (dict == nil) {
        return nil;
    }
    
    NSMutableArray * discogsTracks = [NSMutableArray new];
    NSArray* discogsTracklist = [((NSArray<NSDictionary*>*)dict[@"tracklist"])
         sortedArrayUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull obj1, NSDictionary*  _Nonnull obj2) {
            return [obj1[@"position"] compare:obj2[@"position"] options:NSNumericSearch];
        }];
    for (NSDictionary * track in discogsTracklist) {
        NSString* type = track[@"type_"];
        if ([type isEqualToString:@"track"]) {
            NSString * title = track[@"title"];
            if (title.length == 0) {
                continue;
            }
            NSMutableString* artist = [NSMutableString new];
            NSString* join = nil;
            for (NSDictionary * artistData in track[@"artists"]) {
                [artist appendString:join ?: @""];
                [artist appendString:[artistData[@"anv"] nilIfEmpty] ?: artistData[@"name"]];
                join = [NSString stringWithFormat:@" %@ ", [artistData[@"join"] nilIfEmpty] ?: @","];
            }
            NSString* position = track[@"position"];
            [discogsTracks addObject:[[DiscogsReleaseTrack alloc] initWithPosition:position title:title artist:artist.nilIfEmpty]];
        } else if ([type isEqualToString:@"index"]) {
            NSMutableArray<NSString*>* positions = [NSMutableArray new];

            NSMutableString* artist = [NSMutableString new];
            NSString* join = nil;
            for (NSDictionary * artistData in track[@"artists"]) {
                [artist appendString:join ?: @""];
                [artist appendString:[artistData[@"anv"] nilIfEmpty] ?: artistData[@"name"]];
            }
            
            NSMutableArray<NSString*>* subtitles = [NSMutableArray new];
            for (NSDictionary* subtrack in track[@"sub_tracks"]) {
                if ([subtrack[@"position"] length] > 0) {
                    [positions addObject:subtrack[@"position"]];
                }
                for (NSDictionary * artistData in subtrack[@"artists"]) {
                    [artist appendString:join ?: @""];
                    [artist appendString:[artistData[@"anv"] nilIfEmpty] ?: artistData[@"name"]];
                    join = [NSString stringWithFormat:@" %@ ", [artistData[@"join"] nilIfEmpty] ?: @","];
                }
                if ([subtrack[@"title"] length] > 0) {
                    [subtitles addObject:subtrack[@"title"]];
                }
            }
            
            NSString* subtitlesJoined = [subtitles componentsJoinedByString:@", "];
            NSString* title = [track[@"title"] length] > 0
                ? [NSString stringWithFormat:@"%@ (%@)", track[@"title"], subtitlesJoined]
                : subtitlesJoined;
            
            [discogsTracks addObject:[[DiscogsReleaseTrack alloc] initWithPosition:[positions componentsJoinedByString:@", "]
                                                                             title:title
                                                                            artist:artist.nilIfEmpty]];
        }
    }

    NSMutableString* albumArtist = [NSMutableString new];
    NSString* join = nil;
    for (NSDictionary* albumArtistData in dict[@"artists"]) {
        [albumArtist appendString:join ?: @""];
        [albumArtist appendString:[albumArtistData[@"anv"] nilIfEmpty] ?: albumArtistData[@"name"]];
        join = [NSString stringWithFormat:@" %@ ", [albumArtistData[@"join"] nilIfEmpty] ?: @","];
    }
    
    NSMutableArray<NSString*>* genres = [NSMutableArray new];
    for (NSString* genre in dict[@"genres"]) {
        [genres addObject:genre];
    }
    for (NSString* genre in dict[@"styles"]) {
        [genres addObject:genre];
    }
    
    NSString* releaseDate = dict[@"released"];
    NSString* album = dict[@"title"];
    
    NSMutableArray<DiscogsReleaseCatalogEntry*>* catalogEntries = [NSMutableArray new];
    for (NSDictionary* catalogEntry in dict[@"labels"]) {
        [catalogEntries addObject:[[DiscogsReleaseCatalogEntry alloc] initWithLabel:catalogEntry[@"name"]
                                                                            catalog:catalogEntry[@"catno"]]];
    }

    NSString* originalDate = nil;
    NSNumber* masterId = dict[@"master_id"];
    if (masterId != nil) {
        NSURL * masterURL = [NSURL URLWithString:[@"http://api.discogs.com/masters/" stringByAppendingString:masterId.stringValue]];

        NSData * data = [NSData dataWithContentsOfURL:masterURL options:NSDataReadingUncached error:error];
        if (data == nil) {
            return nil;
        }

        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
        if (dict == nil) {
            return nil;
        }

        originalDate = [dict[@"year"] stringValue];

        if ([releaseDate hasPrefix:originalDate]) {
            originalDate = nil;
        }
    }

    if (originalDate.length < 4) {
        originalDate = nil;
    }
    
    return [[DiscogsReleaseData alloc] initWithAlbumArtist:albumArtist
                                                    genres:genres
                                                     album:album
                                                    tracks:discogsTracks
                                               releaseDate:releaseDate
                                              originalDate:originalDate
                                            catalogEntries:catalogEntries];
}

@end
