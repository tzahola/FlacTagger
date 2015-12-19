//
//  SynchronizedScrollView.h
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SynchronizedScrollView : NSScrollView {
    NSScrollView* synchronizedScrollView; // not retained
}

- (void)setSynchronizedScrollView:(NSScrollView*)scrollview;
- (void)stopSynchronizing;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;

@end
