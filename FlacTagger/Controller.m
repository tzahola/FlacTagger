//
//  Controller.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "Controller.h"
#import "DirectoryLister.h"

@interface Controller ()

@property MainWindowController * mainWindowController;
@property TagEditorWindowController * tagEditorWindowController;
@property TagFromDiscogsWindowController * tagFromDiscogsWindowController;
@property TrackNumberingWindowController * trackNumberingWindowController;
@property FileRenamingWindowController * fileRenamingWindowController;

@property NSMutableArray * files;
@property NSArray * editedFiles;

@property DiscogsReleaseDataLoader * releaseDataLoader;
@property DiscogsReleaseData * releaseData;

@end

@implementation Controller

-(id)init{
    if(self = [super init]){
        self.files = [NSMutableArray new];
    }
    return self;
}

-(void)applicationDidFinishedLaunching:(id)appDelegate{
    
    self.releaseDataLoader = [DiscogsReleaseDataLoader new];
    
    self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
    self.mainWindowController.delegate = self;
    self.mainWindowController.dataSource = self;
    [self.mainWindowController showWindow:self];
}

-(void)mainWindowController:(MainWindowController *)controller didDropFiles:(NSArray *)filenames{
    
    [self addFiles:filenames];
    [self.mainWindowController refresh];
}

-(void)addFiles:(NSArray *)filenames{
    
    NSMutableArray * files = [NSMutableArray new];
    
    for(NSString * path in filenames){
        BOOL isDirectory;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        if(exists){
            if(isDirectory){
                NSError * error;
                NSArray * flacPaths = [DirectoryLister listFilesRecursivelyFrom:path withFilter:^BOOL(NSString *fileName) {
                    return [fileName.pathExtension.lowercaseString isEqualToString:@"flac"];
                } error:&error];
                
                if(flacPaths){
                    [files addObjectsFromArray:flacPaths];
                }else{
                    [[NSAlert alertWithError:error] runModal];
                }
            }else if([path.pathExtension.lowercaseString isEqualToString:@"flac"]){
                [files addObject:path.stringByStandardizingPath];
            }
        }
    }
    
    for(NSString * filename in files){
        NSError * error;
        FileWithTags * fileWithTags = [[FileWithTags alloc] initWithFilename:filename error:&error];
        if(fileWithTags){
            [self.files addObject:fileWithTags];
        }else{
            [[NSAlert alertWithError:error] runModal];
        }
    }
}

-(NSArray *)filesForMainWindowController:(MainWindowController *)controller{
    return self.files;
}

-(void)mainWindowController:(MainWindowController *)controller editFiles:(NSArray *)files{
    self.editedFiles = files;
    
    self.tagEditorWindowController = [[TagEditorWindowController alloc] initWithWindowNibName:NSStringFromClass([TagEditorWindowController class])];
    self.tagEditorWindowController.delegate = self;
    self.tagEditorWindowController.dataSource = self;
    [self.tagEditorWindowController refresh];
    [self.mainWindowController.window beginSheet:self.tagEditorWindowController.window completionHandler:nil];
}

-(void)tagEditorFinishedEditing:(TagEditorWindowController *)controller result:(NSArray *)result{
    for(TagEditorWindowControllerResult * resultItem in result){
        NSError * error;
        BOOL didWrite = [resultItem.file writeTags:resultItem.editedTags error:&error];
        if(!didWrite){
            [[NSAlert alertWithError:error] runModal];
        }
    }
    
    [self.mainWindowController refresh];
    [self.mainWindowController.window endSheet:self.tagEditorWindowController.window];
    self.tagEditorWindowController = nil;
}

-(void)tagEditorCancelledEditing:(TagEditorWindowController *)controller{
    self.editedFiles = nil;
    [self.mainWindowController.window endSheet:self.tagEditorWindowController.window];
    self.tagEditorWindowController = nil;
}

-(NSArray *)filesForTagEditorWindowController:(TagEditorWindowController *)controller{
    return self.editedFiles;
}

-(void)mainWindowController:(MainWindowController *)controller tagFilesFromDiscogs:(NSArray *)files{
    
    self.tagFromDiscogsWindowController = [[TagFromDiscogsWindowController alloc] initWithWindowNibName:NSStringFromClass([TagFromDiscogsWindowController class])];
    self.tagFromDiscogsWindowController.delegate = self;
    self.tagFromDiscogsWindowController.dataSource = self;
    
    self.editedFiles = files;
    [self.tagFromDiscogsWindowController startWizard];
    [self.mainWindowController.window beginSheet:self.tagFromDiscogsWindowController.window completionHandler:nil];
}

-(NSArray *)tagFromDiscogsWindowControllerFiles:(TagFromDiscogsWindowController *)controller{
    return self.editedFiles;
}

-(DiscogsReleaseData *)tagFromDiscogsWindowController:(TagFromDiscogsWindowController *)controller fetchDataForRelease:(NSString *)releaseID{
    NSError *error;
    self.releaseData = [self.releaseDataLoader loadDataForReleaseId:releaseID error:&error];
    if(self.releaseData){
        return self.releaseData;
    }else{
        [[NSAlert alertWithError:error] runModal];
        return nil;
    }
}

-(void)tagFromDiscogsWindowControllerDidCancel:(TagFromDiscogsWindowController *)controller{
    [self.mainWindowController.window endSheet:self.tagFromDiscogsWindowController.window];
    self.tagFromDiscogsWindowController = nil;
}

-(void)tagFromDiscogsWindowController:(TagFromDiscogsWindowController *)controller finishedWithPairs:(NSArray *)pairings{
    BOOL needsAlbumArtist = NO;
    NSString * albumArtist = [self.releaseData.albumArtists componentsJoinedByString:@", "];
    for(DiscogsTaggingPair * pair in pairings){
        if(pair.discogsData.artists.count > 0){
            NSString * trackArtist = [pair.discogsData.artists componentsJoinedByString:@", "];
            if(![trackArtist isEqualToString:albumArtist]){
                needsAlbumArtist = YES;
                break;
            }
        }
    }
    
    for(DiscogsTaggingPair * pair in pairings){
        NSMutableDictionary * tags = [pair.file.tags mutableCopy];
        tags[@"TITLE"] = pair.discogsData.title;
        tags[@"ALBUM"] = self.releaseData.album;
        NSString * artist;
        if(pair.discogsData.artists.count > 0){
            artist = [pair.discogsData.artists componentsJoinedByString:@", "];
        }else{
            artist = [self.releaseData.albumArtists componentsJoinedByString:@", "];
        }
        tags[@"ARTIST"] = artist;
        if(needsAlbumArtist){
            tags[@"ALBUMARTIST"] = [self.releaseData.albumArtists componentsJoinedByString:@", "];
        }else{
            [tags removeObjectForKey:@"ALBUMARTIST"];
        }
        
        if(self.releaseData.releaseDate){
            tags[@"DATE"] = self.releaseData.releaseDate;
        }else{
            [tags removeObjectForKey:@"DATE"];
        }
        
        if(self.releaseData.genres){
            tags[@"GENRE"] = [self.releaseData.genres componentsJoinedByString:@", "];
        }else{
            [tags removeObjectForKey:@"GENRE"];
        }
        
        NSError * error;
        BOOL didWrite = [pair.file writeTags:tags error:&error];
        if(!didWrite){
            [[NSAlert alertWithError:error] runModal];
        }
    }
    
    [self.mainWindowController.window endSheet:self.tagFromDiscogsWindowController.window];
    [self.mainWindowController refresh];
    
    self.tagFromDiscogsWindowController = nil;
}

-(void)mainWindowController:(MainWindowController *)controller numberFiles:(NSArray *)files{
    self.editedFiles = files;
    self.trackNumberingWindowController = [[TrackNumberingWindowController alloc] initWithWindowNibName:NSStringFromClass([TrackNumberingWindowController class])];
    self.trackNumberingWindowController.delegate = self;
    self.trackNumberingWindowController.dataSource = self;
    [self.trackNumberingWindowController refresh];
    [self.mainWindowController.window beginSheet:self.trackNumberingWindowController.window completionHandler:nil];
}

-(void)trackNumberingWindowController:(TrackNumberingWindowController *)controller
                  finishedWithResults:(NSArray *)trackNumberingResults{
    for(TrackNumberingResult * result in trackNumberingResults){
        NSMutableDictionary * tags = [result.file.tags mutableCopy];
        tags[@"TRACKNUMBER"] = [NSString stringWithFormat:@"%d", (int)result.trackNumber];
        tags[@"TRACKTOTAL"] = [NSString stringWithFormat:@"%d", (int)result.trackTotal];
        tags[@"DISCNUMBER"] = [NSString stringWithFormat:@"%d", (int)result.discNumber];
        tags[@"DISCTOTAL"] = [NSString stringWithFormat:@"%d", (int)result.discTotal];
        NSError * error;
        BOOL didWrite = [result.file writeTags:tags error:&error];
        if(!didWrite){
            [[NSAlert alertWithError:error] runModal];
        }
    }
    [self.mainWindowController.window endSheet:self.trackNumberingWindowController.window];
    self.trackNumberingWindowController = nil;
    [self.mainWindowController refresh];
}

-(void)trackNumberingWindowControllerDidCancel:(TrackNumberingWindowController *)controller{
    [self.mainWindowController.window endSheet:self.trackNumberingWindowController.window];
    self.trackNumberingWindowController = nil;
}

-(NSArray *)filesForTrackNumberingWindowController:(TrackNumberingWindowController *)controller{
    return self.editedFiles;
}

-(void)mainWindowController:(MainWindowController *)controller deleteFiles:(NSArray *)files{
    [self.files removeObjectsInArray:files];
    [self.mainWindowController refresh];
}

-(void)mainWindowController:(MainWindowController *)controller renameFiles:(NSArray *)files{
    self.editedFiles = files;
    self.fileRenamingWindowController = [[FileRenamingWindowController alloc] initWithWindowNibName:NSStringFromClass([FileRenamingWindowController class])];
    self.fileRenamingWindowController.delegate = self;
    self.fileRenamingWindowController.dataSource = self;
    [self.mainWindowController.window beginSheet:self.fileRenamingWindowController.window completionHandler:nil];
}

-(void)fileRenamingWindowController:(FileRenamingWindowController *)controller renameFiles:(NSArray *)renamings{
    for(FileRenaming * renaming in renamings){
        NSError * error;
        BOOL didRename = [renaming.file renameTo:renaming.newFileName error:&error];
        if(!didRename){
            [[NSAlert alertWithError:error] runModal];
        }
    }
    [self.mainWindowController.window endSheet:self.fileRenamingWindowController.window];
    self.fileRenamingWindowController = nil;
}

-(void)fileRenamingWindowControllerCancel:(FileRenamingWindowController *)controller{
    [self.mainWindowController.window endSheet:self.fileRenamingWindowController.window];
    self.fileRenamingWindowController = nil;
}

-(NSArray *)filesForFileRenamingWindowController:(FileRenamingWindowController *)controller{
    return self.editedFiles;
}

@end
