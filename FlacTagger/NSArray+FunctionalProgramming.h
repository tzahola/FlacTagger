//
//  NSArray+FunctionalProgramming.h
//  FlacTagger
//
//  Created by Tamás Zahola on 09/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id(^NSArrayMapBlock)(id obj);

@interface NSArray (FunctionalProgramming)

-(instancetype)mapMaybe:(NSArrayMapBlock)mapBlock;
-(instancetype)map:(NSArrayMapBlock)mapBlock;
-(instancetype)distinct;
-(instancetype)join;
+(NSArray*)arrayByRepeating:(id)obj times:(NSUInteger)times;

@end
