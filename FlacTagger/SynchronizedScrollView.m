//
//  SynchronizedScrollView.m
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "SynchronizedScrollView.h"

@interface SynchronizedScrollView ()
@property (nonatomic, strong) id observer;
@end

@implementation SynchronizedScrollView

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setSynchronizedScrollView:(NSScrollView *)synchronizedScrollView
{
    if (synchronizedScrollView == _synchronizedScrollView) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
    _synchronizedScrollView = synchronizedScrollView;
    
    if (self.synchronizedScrollView != nil) {
        self.synchronizedScrollView.contentView.postsBoundsChangedNotifications = YES;
        self.observer = [[NSNotificationCenter defaultCenter]
            addObserverForName:NSViewBoundsDidChangeNotification
            object:self.synchronizedScrollView.contentView
            queue:nil
            usingBlock:^(NSNotification * _Nonnull note) {
                NSClipView *changedContentView = note.object;
                if (!NSEqualPoints(self.contentView.bounds.origin, changedContentView.bounds.origin)) {
                    [self.contentView scrollToPoint:changedContentView.bounds.origin];
                    [self reflectScrolledClipView:self.contentView];
                }
            }];
    }
}

@end
