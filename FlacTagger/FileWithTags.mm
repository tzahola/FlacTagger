//
//  FileWithTags.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "FileWithTags.h"
#import <FLAC++/metadata.h>

NSString * FileWithTagsErrorDomain = @"FileWithTagsErrorDomain";

@interface FileWithTags ()
@end

@implementation FileWithTags

-(instancetype)initWithFilename:(NSString *)filename error:(NSError *__autoreleasing *)error{
    if(self = [super init]){
        _filename = [filename copy];
        BOOL didRefresh = [self refreshWithError:error];
        if(!didRefresh){
            return nil;
        }
    }
    return self;
}

-(BOOL)writeTags:(NSDictionary *)tags error:(NSError *__autoreleasing *)error{
    
    FLAC::Metadata::Chain metadataChain;
    metadataChain.read(self.filename.UTF8String);
    
    if(!metadataChain.is_valid()){
        *error = [NSError errorWithDomain:FileWithTagsErrorDomain code:FileWithTagsInvalidFileError userInfo:nil];
        return NO;
    }
    
    FLAC::Metadata::Iterator metadataIterator;
    metadataIterator.init(metadataChain);
    
    if(!metadataIterator.is_valid()){
        *error = [NSError errorWithDomain:FileWithTagsErrorDomain code:FileWithTagsInvalidFileError userInfo:nil];
        return NO;
    }
    
    do{
        if(metadataIterator.get_block_type() == FLAC__METADATA_TYPE_VORBIS_COMMENT){
            metadataIterator.delete_block(true);
        }
    } while(metadataIterator.next());
    
    FLAC::Metadata::VorbisComment * vorbisComment = new FLAC::Metadata::VorbisComment();
    
    [tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString * tag = key;
        NSString * value = obj;
        
        FLAC::Metadata::VorbisComment::Entry entry(tag.UTF8String, value.UTF8String);
        bool didAppend = vorbisComment->append_comment(entry);
        
        NSAssert(didAppend, @"Failed to add tag: '%@' -> '%@'", tag, value);
    }];
    
    metadataIterator.insert_block_after(vorbisComment);
    metadataChain.sort_padding();
    metadataChain.merge_padding();
    bool didWrite = metadataChain.write(true, false);
    
    if(!didWrite){
        *error = [NSError errorWithDomain:FileWithTagsErrorDomain code:FileWithTagsFailedToWriteError userInfo:nil];
        return NO;
    }
    
    return [self refreshWithError:error];
}

-(BOOL)refreshWithError:(NSError *__autoreleasing *)error{
    NSMutableDictionary * tags = [NSMutableDictionary new];
    
    FLAC::Metadata::VorbisComment vorbisComments;
    FLAC::Metadata::get_tags(self.filename.UTF8String, vorbisComments);
    
    if(!vorbisComments.is_valid()){
        *error = [NSError errorWithDomain:FileWithTagsErrorDomain code:FileWithTagsInvalidFileError userInfo:nil];
        return NO;
    }
    
    for(int i = 0; i < vorbisComments.get_num_comments(); i++){
        FLAC::Metadata::VorbisComment::Entry entry = vorbisComments.get_comment(i);
        NSString * tagName = [[NSString stringWithCString:entry.get_field_name() encoding:NSUTF8StringEncoding] uppercaseString];
        NSString * tagValue = [NSString stringWithCString:entry.get_field_value() encoding:NSUTF8StringEncoding];
        
        tags[tagName] = tagValue;
    }
    
    _tags = tags;
    
    return YES;
}

-(BOOL)renameTo:(NSString *)filename error:(NSError *__autoreleasing *)error{
    NSString * newPath = [[self.filename stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename];
    if([newPath isEqualToString:_filename]){
        return YES;
    }else{
        BOOL didRename = [[NSFileManager defaultManager] moveItemAtPath:self.filename toPath:newPath error:error];
        if(didRename){
            _filename = newPath;
        }
        return didRename;
    }
}

@end
