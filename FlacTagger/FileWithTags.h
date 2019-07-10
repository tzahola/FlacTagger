//
//  FileWithTags.h
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * FileWithTagsErrorDomain;

enum {
    FileWithTagsInvalidFileError,
    FileWithTagsFailedToWriteError
};

@interface FileWithTags : NSObject

@property (readonly) NSString * filename;
@property (readonly) NSDictionary * tags;

-(instancetype)initWithFilename:(NSString *)filename error:(NSError * __autoreleasing *)error;
-(BOOL)refreshWithError:(NSError * __autoreleasing *)error;
-(BOOL)writeTags:(NSDictionary *)tags error:(NSError * __autoreleasing *)error;
-(BOOL)renameTo:(NSString*)filename error:(NSError * __autoreleasing *)error;

@end
