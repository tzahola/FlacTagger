//
//  TableViewWithActions.m
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "TableViewWithActions.h"

@implementation TableViewWithActions

@dynamic delegate;

-(void)delete:(id)sender{
    [self.delegate tableViewDelete:self];
}

@end
