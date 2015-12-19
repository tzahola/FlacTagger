//
//  DirectoryLister.m
//  FlacTagger
//
//  Created by Tamás Zahola on 17/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "DirectoryLister.h"
#import <dirent.h>
#import <sys/stat.h>

NSString * DirecotryListerErrorDomain = @"DirecotryListerErrorDomain";

@implementation DirectoryLister

+(NSArray *)listFilesRecursivelyFrom:(NSString *)path withFilter:(FileFilterBlock)filterBlock error:(NSError *__autoreleasing *)error{
    
    NSString * standardizedPath = [path stringByStandardizingPath];
    NSMutableArray * result = [NSMutableArray new];
    
    DIR * dir = opendir(standardizedPath.UTF8String);
    if(!dir){
        *error = [NSError errorWithDomain:DirecotryListerErrorDomain code:DirecotryListerGeneralError userInfo:nil];
        return nil;
    }
    
    struct dirent * dirent;
    while((dirent = readdir(dir))){
        if(strcmp(".", dirent->d_name) != 0 && strcmp("..", dirent->d_name) != 0){
            NSString * path = [standardizedPath stringByAppendingPathComponent:[NSString stringWithUTF8String:dirent->d_name]];
            if(dirent->d_type == DT_DIR){
                NSArray * entries = [self listFilesRecursivelyFrom:path withFilter:filterBlock error:error];
                if(!entries){
                    return nil;
                }
                [result addObjectsFromArray:entries];
            }else if(filterBlock(path)){
                [result addObject:path];
            }
        }
    }
    closedir(dir);
    
    return result;
}

@end
