//
//  NSArray+FunctionalProgramming.m
//  FlacTagger
//
//  Created by Tamás Zahola on 09/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "NSArray+FunctionalProgramming.h"

@implementation NSArray (FunctionalProgramming)

-(instancetype)mapMaybe:(NSArrayMapBlock)mapBlock{
    NSMutableArray * result = [NSMutableArray new];
    for(id obj in self){
        id item = mapBlock(obj);
        if(item){
            [result addObject:item];
        }
    }
    return result;
}

-(instancetype)map:(NSArrayMapBlock)mapBlock{
    NSMutableArray * result = [NSMutableArray new];
    for(id obj in self){
        [result addObject:mapBlock(obj)];
    }
    return result;
}

-(instancetype)distinct{
    return [[NSOrderedSet orderedSetWithArray:self] array];
}

-(instancetype)join{
    NSMutableArray * result = [NSMutableArray new];
    for(NSArray * array in self){
        [result addObjectsFromArray:array];
    }
    return result;
}

+(NSArray *)arrayByRepeating:(id)obj times:(NSUInteger)times{
    NSMutableArray * result = [NSMutableArray new];
    for(int i = 0; i < times; i++){
        [result addObject:obj];
    }
    return result;
}

@end
