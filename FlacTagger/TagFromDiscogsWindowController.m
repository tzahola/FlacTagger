//
//  TagFromDiscogsWindowController.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "TagFromDiscogsWindowController.h"
#import "SynchronizedScrollView.h"

@implementation TagFromDiscogsTableViewCell
@end

@implementation DiscogsTaggingPair

-(instancetype)initWithFile:(FileWithTags *)file discogsData:(DiscogsReleaseTrack *)discogsData{
    if(self = [super init]){
        _file = file;
        _discogsData = discogsData;
    }
    return self;
}

@end

@interface TagFromDiscogsWindowController ()

@property NSColor * missingDataBackgroundColor;

@property (weak) IBOutlet NSTextField *albumArtistLabel;
@property (weak) IBOutlet NSTextField *albumTitleLabel;
@property (weak) IBOutlet NSTextField *releaseDateLabel;
@property (weak) IBOutlet NSTextField *genreLabel;

@property (strong) IBOutlet NSView *releaseIdView;
@property (weak) IBOutlet NSTextField *releaseIdTextField;
@property (strong) IBOutlet NSView *discogsDataPairingView;
@property NSView * emptyView;
@property (weak) IBOutlet SynchronizedScrollView *filesTableViewScrollView;
@property (weak) IBOutlet NSTableView *filesTableView;
@property (weak) IBOutlet SynchronizedScrollView *discogsDataTableViewScrollView;
@property (weak) IBOutlet NSTableView *discogsDataTableView;

@property DiscogsReleaseData * releaseData;
@property NSArray * files;

@property NSMutableArray * trackRowsData;
@property NSMutableArray * fileRowsData;

@end

@implementation TagFromDiscogsWindowController

-(void)windowDidLoad{
    [super windowDidLoad];
    
    self.missingDataBackgroundColor = [NSColor colorWithRed:1 green:0.7 blue:0.7 alpha:1];
    
    self.emptyView = [[NSView alloc] initWithFrame:NSZeroRect];
    [self.filesTableViewScrollView setSynchronizedScrollView:self.discogsDataTableViewScrollView];
    [self.discogsDataTableViewScrollView setSynchronizedScrollView:self.filesTableViewScrollView];
    
    [self.filesTableView registerForDraggedTypes:@[ (NSString *)kUTTypeData ]];
    [self.discogsDataTableView registerForDraggedTypes:@[ (NSString *)kUTTypeData ]];
}

-(void)startWizard{
    [self.window setContentSize:self.releaseIdView.frame.size];
    self.window.contentView = self.releaseIdView;
}

- (IBAction)releaseIdOKButtonPressed:(id)sender {
    if(self.releaseIdTextField.stringValue.length == 0) return;
    
    self.releaseData = [self.dataSource tagFromDiscogsWindowController:self fetchDataForRelease:self.releaseIdTextField.stringValue];
    if(!self.releaseData) return;
    
    self.files = [self.dataSource tagFromDiscogsWindowControllerFiles:self];
    
    self.trackRowsData = [NSMutableArray new];
    self.fileRowsData = [NSMutableArray new];
    NSInteger rowCount = MAX(self.releaseData.tracks.count, self.files.count);
    for(int i = 0; i < rowCount; i++){
        if(i < self.releaseData.tracks.count){
            [self.trackRowsData addObject:self.releaseData.tracks[i]];
        }else{
            [self.trackRowsData addObject:[NSNull null]];
        }
        
        if(i < self.files.count){
            [self.fileRowsData addObject:self.files[i]];
        }else{
            [self.fileRowsData addObject:[NSNull null]];
        }
    }
    
    if(self.releaseData.albumArtists.count > 0){
        self.albumArtistLabel.stringValue = [self.releaseData.albumArtists componentsJoinedByString:@", "];
    }else{
        self.albumArtistLabel.stringValue = @"[ no data ]";
    }
    
    self.albumTitleLabel.stringValue = self.releaseData.album;
    
    if(self.releaseData.releaseDate){
        self.releaseDateLabel.stringValue = self.releaseData.releaseDate;
    }else{
        self.releaseDateLabel.stringValue = @"[ no data ]";
    }
    
    if(self.releaseData.genres.count > 0){
        self.genreLabel.stringValue = [self.releaseData.genres componentsJoinedByString:@", "];
    }else{
        self.genreLabel.stringValue = @"[ no data ]";
    }
    
    self.window.contentView = self.emptyView;
    [self.window setFrame:[self.window frameRectForContentRect:self.discogsDataPairingView.frame] display:YES animate:YES];
    self.window.contentView = self.discogsDataPairingView;
}

- (IBAction)releaseIdCancelButtonPressed:(id)sender {
    [self.delegate tagFromDiscogsWindowControllerDidCancel:self];
}

- (IBAction)discogsDataPairingCancelButtonPressed:(id)sender {
    [self.delegate tagFromDiscogsWindowControllerDidCancel:self];
}

- (IBAction)discogsDataPairingOKButtonPressed:(id)sender {
    NSMutableArray * pairs = [NSMutableArray new];
    NSAssert(self.trackRowsData.count == self.fileRowsData.count, @"File rows count and track rows count must be equal!");
    for(int i = 0; i < self.trackRowsData.count; i++){
        if(self.trackRowsData[i] != [NSNull null] && self.fileRowsData[i] != [NSNull null]){
            DiscogsTaggingPair * pair = [[DiscogsTaggingPair alloc] initWithFile:self.fileRowsData[i] discogsData:self.trackRowsData[i]];
            [pairs addObject:pair];
        }
    }
    [self.delegate tagFromDiscogsWindowController:self finishedWithPairs:pairs];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return MAX(self.releaseData.tracks.count, self.files.count);
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    TagFromDiscogsTableViewCell * cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if(tableView == self.discogsDataTableView){
        if(self.trackRowsData[row] == [NSNull null]){
            cell.textField.stringValue = @"[ no data ]";
        }else{
            DiscogsReleaseTrack * track = self.trackRowsData[row];
            NSString * artistsString;
            if(track.artists.count > 0){
                artistsString = [track.artists componentsJoinedByString:@"; "];
            }else{
                artistsString = [self.releaseData.albumArtists componentsJoinedByString:@"; "];
            }
            cell.textField.stringValue = [NSString stringWithFormat:@"%@ - %@", artistsString, track.title];
        }
    }else if(tableView == self.filesTableView){
        if(self.fileRowsData[row] == [NSNull null]){
            cell.textField.stringValue = @"[ no file ]";
        }else{
            FileWithTags * file = self.fileRowsData[row];
            cell.textField.stringValue = [[file.filename pathComponents] lastObject];
        }
    }else{
        NSAssert(NO, @"Invalid tableView: '%@", tableView);
        return nil;
    }
    
    return cell;
}

-(void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row{
    if((tableView == self.discogsDataTableView && self.trackRowsData[row] == [NSNull null]) ||
       (tableView == self.filesTableView && self.fileRowsData[row] == [NSNull null])){
        rowView.backgroundColor = self.missingDataBackgroundColor;
    }
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation{
    if(dropOperation == NSTableViewDropAbove && tableView == [info draggingSource]){
        return NSDragOperationMove;
    }else{
        return NSDragOperationNone;
    }
}

-(id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row{
    NSPasteboardItem * result = [[NSPasteboardItem alloc] init];
    NSData * data;
    if(tableView.selectedRowIndexes.count > 0 && [tableView.selectedRowIndexes containsIndex:row]){
        data = [NSKeyedArchiver archivedDataWithRootObject:tableView.selectedRowIndexes];
    }else{
        data = [NSKeyedArchiver archivedDataWithRootObject:[NSIndexSet indexSetWithIndex:row]];
    }
    [result setData:data forType:(NSString*)kUTTypeData];
    return result;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation{
    
    NSIndexSet * indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:(NSString *)kUTTypeData]];
    NSInteger indexesLessThanTargetIndex = [indexSet countOfIndexesInRange:NSMakeRange(0, row)];
    
    NSMutableArray * rowData;
    if(tableView == self.filesTableView){
        rowData = self.fileRowsData;
    }else if(tableView == self.discogsDataTableView){
        rowData = self.trackRowsData;
    }else{
        NSAssert(NO, @"Invalid tableView: '%@'", tableView);
    }
    
    NSArray * objects = [rowData objectsAtIndexes:indexSet];
    [rowData removeObjectsAtIndexes:indexSet];
    NSIndexSet * newIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row - indexesLessThanTargetIndex, indexSet.count)];
    [rowData insertObjects:objects atIndexes:newIndexSet];
    [tableView selectRowIndexes:newIndexSet byExtendingSelection:NO];
    [tableView reloadData];
    
    return YES;
}

@end
