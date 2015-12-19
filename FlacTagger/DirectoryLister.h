//
//  DirectoryLister.h
//  FlacTagger
//
//  Created by Tamás Zahola on 17/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * DirecotryListerErrorDomain;

enum{
    DirecotryListerGeneralError
};

typedef BOOL(^FileFilterBlock)(NSString * fileName);

@interface DirectoryLister : NSObject

+(NSArray*)listFilesRecursivelyFrom:(NSString*)path withFilter:(FileFilterBlock)filterBlock error:(NSError * __autoreleasing *)error;

@end
