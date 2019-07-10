//
//  TableViewWithActions.h
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TableViewWithActions;

@protocol TableViewWithActionsDelegate <NSTableViewDelegate>

@optional
-(void)tableViewDelete:(TableViewWithActions*)tableView;

@end

@interface TableViewWithActions : NSTableView

@property (weak) id<TableViewWithActionsDelegate> delegate;

@end
