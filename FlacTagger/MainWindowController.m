//
//  MainWindowController.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "MainWindowController.h"
#import "FileWithTags.h"

@interface NSPasteboard (FileURLs)

@property (nonatomic, nullable, readonly) NSArray<NSURL*>* fileURLs;

@end

@implementation NSPasteboard (FileURLs)

- (NSArray<NSURL *> *)fileURLs {
    NSArray<NSPasteboardItem*>* items = self.pasteboardItems;
    if (items == nil) {
        return nil;
    }

    NSMutableArray<NSURL*>* fileURLs = [NSMutableArray new];
    for (NSPasteboardItem* item in items) {
        NSData* fileURLData = [item dataForType:NSPasteboardTypeFileURL];
        if (fileURLData == nil) {
            continue;
        }

        NSURL* fileURL = [NSURL URLWithDataRepresentation:fileURLData relativeToURL:nil];
        NSAssert(fileURL.isFileURL, @"");

        [fileURLs addObject:fileURL];
    }
    return fileURLs;
}

@end

@interface MainWindowController ()

@property (weak) IBOutlet NSTableView *tableView;
@property NSArray * files;

@end

@implementation MainWindowController

- (IBAction)edit:(id)sender {
    [self.delegate mainWindowController:self editFiles:[self selectedFiles]];
}

- (IBAction)numberTracks:(id)sender {
    [self.delegate mainWindowController:self numberFiles:[self selectedFiles]];
}

- (IBAction)tagFromDiscogs:(id)sender {
    [self.delegate mainWindowController:self tagFilesFromDiscogs:[self selectedFiles]];
}

- (IBAction)renameFiles:(id)sender {
    [self.delegate mainWindowController:self renameFiles:[self selectedFiles]];
}

-(void)windowDidLoad{
    [super windowDidLoad];
    [self.tableView registerForDraggedTypes:@[ NSPasteboardTypeFileURL ]];
    
    NSTableColumn * titleColumn = [[NSTableColumn alloc] initWithIdentifier:@"TITLE"];
    titleColumn.headerCell = [[NSTableHeaderCell alloc] initTextCell:@"Title"];
    titleColumn.editable = NO;
    
    NSTableColumn * artistColumn = [[NSTableColumn alloc] initWithIdentifier:@"ARTIST"];
    artistColumn.headerCell = [[NSTableHeaderCell alloc] initTextCell:@"Artist"];
    artistColumn.editable = NO;
    
    NSTableColumn * albumColumn = [[NSTableColumn alloc] initWithIdentifier:@"ALBUM"];
    albumColumn.headerCell = [[NSTableHeaderCell alloc] initTextCell:@"Album"];
    albumColumn.editable = NO;
    
    NSTableColumn * tracknumberColumn = [[NSTableColumn alloc] initWithIdentifier:@"TRACKNUMBER"];
    tracknumberColumn.headerCell = [[NSTableHeaderCell alloc] initTextCell:@"Track no."];
    tracknumberColumn.editable = NO;
    
    NSTableColumn * genreColumn = [[NSTableColumn alloc] initWithIdentifier:@"GENRE"];
    genreColumn.headerCell = [[NSTableHeaderCell alloc] initTextCell:@"Genre"];
    genreColumn.editable = NO;
    
    [self.tableView addTableColumn:tracknumberColumn];
    [self.tableView addTableColumn:artistColumn];
    [self.tableView addTableColumn:titleColumn];
    [self.tableView addTableColumn:albumColumn];
    [self.tableView addTableColumn:genreColumn];
    
    [self.tableView sizeLastColumnToFit];

    [self.window makeFirstResponder:self.tableView];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.files.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if (tableView == self.tableView) {
        FileWithTags * file = self.files[row];
        NSString * value = file.tags[tableColumn.identifier];
        return value == nil ? @"?" : value;
    } else {
        return nil;
    }
}

- (IBAction)paste:(id)sender {
    NSArray<NSURL*>* fileURLs = NSPasteboard.generalPasteboard.fileURLs;
    [self.delegate mainWindowController:self didDropFileURLs:fileURLs];
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation{
    if (tableView == self.tableView) {
        if (dropOperation == NSTableViewDropAbove) {
            return NSDragOperationEvery;
        } else {
            return NSDragOperationNone;
        }
    } else {
        return NSDragOperationNone;
    }
}

-(BOOL)tableView:tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    if (tableView != self.tableView) {
        return NO;
    }

    [self.delegate mainWindowController:self didDropFileURLs:info.draggingPasteboard.fileURLs];
    
    return YES;
}

-(void)refresh{
    self.files = [self.dataSource filesForMainWindowController:self];
    [self.tableView reloadData];
}

-(NSArray*)selectedFiles{
    return [self.files objectsAtIndexes:self.tableView.selectedRowIndexes];
}

-(void)windowWillClose:(NSNotification *)notification{
    [[NSApplication sharedApplication] stopModal];
}

-(void)tableViewDelete:(TableViewWithActions *)tableView{
    [self.delegate mainWindowController:self deleteFiles:[self selectedFiles]];
    [tableView deselectAll:self];
}

@end
