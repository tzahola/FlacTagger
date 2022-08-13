//
//  SynchronizedScrollView.h
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SynchronizedScrollView : NSScrollView

@property (nonatomic, nullable, weak) NSScrollView* synchronizedScrollView;

@end
