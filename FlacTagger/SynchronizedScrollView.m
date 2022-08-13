//
//  SynchronizedScrollView.m
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "SynchronizedScrollView.h"

@implementation SynchronizedScrollView

- (void)setSynchronizedScrollView:(NSScrollView*)scrollview {
    if (_synchronizedScrollView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSViewBoundsDidChangeNotification
                                                      object:_synchronizedScrollView.contentView];
        _synchronizedScrollView = nil;
    }
    
    _synchronizedScrollView = scrollview;
    
    if (_synchronizedScrollView) {
        NSView *synchronizedContentView = [_synchronizedScrollView contentView];
        synchronizedContentView.postsBoundsChangedNotifications = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronizedViewContentBoundsDidChange:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:synchronizedContentView];
    }
}

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification {
    NSClipView *contentView = notification.object;
    
    NSPoint newOrigin = contentView.documentVisibleRect.origin;
    if (!NSEqualPoints(self.contentView.bounds.origin, newOrigin)) {
        [self.contentView scrollToPoint:newOrigin];
        [self reflectScrolledClipView:self.contentView];
    }
}

@end
