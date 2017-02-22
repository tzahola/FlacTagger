//
//  TagFromDiscogsWindowController.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "TagFromDiscogsWindowController.h"

#import <WebKit/WebKit.h>

#import "SynchronizedScrollView.h"

static NSString* const kIphoneUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_4 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10B350 Safari/8536.25";

@interface HeadingTrackTableCellView : NSTableCellView
@property (weak) IBOutlet NSPopUpButton *rolePopUpButton;
@end

@implementation HeadingTrackTableCellView
@end

@class IndexTrackTableCellView;
@protocol IndexTrackTableCellViewDelegate <NSObject>
- (void)indexTrackTableCellViewSplit:(IndexTrackTableCellView*)view;
@end

@interface IndexTrackTableCellView : NSTableCellView
@property (weak) IBOutlet NSTextField *subtitleLabel;
@property (weak) IBOutlet id<IndexTrackTableCellViewDelegate> delegate;
@end

@implementation IndexTrackTableCellView
- (IBAction)splitButtonPressed:(id)sender {
    [self.delegate indexTrackTableCellViewSplit:self];
}
@end

@implementation ChapterData

- (instancetype)initWithTitle:(NSString *)title startTime:(NSTimeInterval)startTime {
    if (self = [super init]) {
        _title = [title copy];
        _startTime = startTime;
    }
    return self;
}

@end

@implementation TrackData

- (instancetype)initWithTitle:(NSString *)title artist:(NSArray<NSString *> *)artists chapters:(NSArray<ChapterData *> *)chapters {
    if (self = [super init]) {
        _title = [title copy];
        _artists = [artists copy];
        _chapters = [chapters copy];
    }
    return self;
}

@end

@implementation TrackGroupData

- (instancetype)initWithTitle:(NSString *)title tracks:(NSArray<TrackData *> *)tracks {
    if (self = [super init]) {
        _title = [title copy];
        _tracks = [tracks copy];
    }
    return self;
}

@end

@implementation DiscData

- (instancetype)initWithTitle:(NSString *)title trackGroups:(NSArray<TrackGroupData *> *)trackGroups {
    if (self = [super init]) {
        _title = [title copy];
        _trackGroups = [trackGroups copy];
    }
    return self;
}

@end

@implementation AlbumData

- (instancetype)initWithAlbumArtists:(NSArray<NSString *> *)albumArtists
                               discs:(NSArray<DiscData *> *)discs
                              genres:(NSArray<NSString *> *)genres
                              styles:(NSArray<NSString *> *)styles
                               label:(NSString * _Nullable)label
                             catalog:(NSString * _Nullable)catalog {
    if (self = [super init]) {
        _albumArtists = [albumArtists copy];
        _discs = [discs copy];
        _genres = [genres copy];
        _styles = [styles copy];
        _label = [label copy];
        _catalog = [catalog copy];
    }
    return self;
}

@end

@implementation DiscogsTaggingPair

- (instancetype)initWithFiles:(NSArray<FileWithTags *> *)files data:(AlbumData *)data {
    if (self = [super init]) {
        _files = [files copy];
        _data = data;
    }
    return self;
}

@end

@interface TagFromDiscogsWindowController () <WebFrameLoadDelegate,IndexTrackTableCellViewDelegate>

@property NSColor * missingDataBackgroundColor;

@property (weak) IBOutlet NSTextField *albumArtistLabel;
@property (weak) IBOutlet NSTextField *albumTitleLabel;
@property (weak) IBOutlet NSTextField *releaseDateLabel;
@property (weak) IBOutlet NSTextField *genreLabel;

@property (strong) IBOutlet NSView *releaseIdView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet WebView *webView;
@property (nonatomic, readonly) BOOL isOnReleasePage;
@property (nonatomic, readonly) NSString* releaseId;
@property (strong) IBOutlet NSView *discogsDataPairingView;
@property NSView * emptyView;

@property (weak) IBOutlet NSTableView *filesTableView;
@property (weak) IBOutlet NSTableView *discogsDataTableView;
@property (weak) IBOutlet NSPopUpButton *labelCatalogueButton;

@property DiscogsReleaseData * releaseData;
@property NSArray<FileWithTags*> * files;

@property NSMapTable* headingRoles;
@property NSMutableArray* fileRowsData;

@end

typedef NS_ENUM(NSInteger, HeadingRole) {
    HeadingRoleDiscTitle = 0,
    HeadingRoleGroupTitle = 1
};

@implementation TagFromDiscogsWindowController
@dynamic isOnReleasePage, releaseId;

+ (NSRegularExpression*)releaseIdRegexp {
    static NSRegularExpression* releaseIdRegexp;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        releaseIdRegexp = [NSRegularExpression
            regularExpressionWithPattern:@"release\\/(\\d+)"
            options:NSRegularExpressionCaseInsensitive
            error:nil];
    });
    return releaseIdRegexp;
}

- (BOOL)isOnReleasePage {
    return self.releaseId != nil;
}

+ (NSSet *)keyPathsForValuesAffectingIsOnReleasePage {
    return [NSSet setWithObject:@"releaseId"];
}

- (NSString*)releaseId {
    if (self.webView.mainFrameURL == nil) return nil;
    
    NSTextCheckingResult* match = [[[self class]
        releaseIdRegexp]
        firstMatchInString:self.webView.mainFrameURL
        options:0
        range:NSMakeRange(0, self.webView.mainFrameURL.length)];
    if (!match || match.range.location == NSNotFound) return nil;
    
    return [self.webView.mainFrameURL substringWithRange:[match rangeAtIndex:1]];
}

+ (NSSet *)keyPathsForValuesAffectingReleaseId {
    return [NSSet setWithObject:@"webView.mainFrameURL"];
}

-(void)windowDidLoad{
    [super windowDidLoad];
    
    self.missingDataBackgroundColor = [NSColor colorWithRed:1 green:0.7 blue:0.7 alpha:1];
    
    self.emptyView = [[NSView alloc] initWithFrame:NSZeroRect];
    
    [self.filesTableView registerForDraggedTypes:@[ (NSString *)kUTTypeData ]];
    [self.discogsDataTableView registerForDraggedTypes:@[ (NSString *)kUTTypeData ]];
    
    self.webView.customUserAgent = kIphoneUserAgent; // force mobile version ;)
    self.webView.frameLoadDelegate = self;
}

- (void)dealloc {
    self.webView.frameLoadDelegate = nil;
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    [self.progressIndicator startAnimation:nil];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    [self.progressIndicator stopAnimation:nil];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    [self.progressIndicator stopAnimation:nil];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    [self.progressIndicator stopAnimation:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.webView && [keyPath isEqualToString:@"loading"]) {
        if (self.webView.loading) {
            [self.progressIndicator startAnimation:self];
        } else {
            [self.progressIndicator stopAnimation:self];
        }
    }
}

-(void)startWizard{
    [self.window setContentSize:self.releaseIdView.frame.size];
    self.window.contentView = self.releaseIdView;
    
    self.files = [self.dataSource tagFromDiscogsWindowControllerFiles:self];
    NSDictionary* tags = self.files[0].tags;
    NSURL* url;
    if (tags[@"ARTIST"] != nil && tags[@"ALBUM"] != nil) {
     url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.discogs.com/search/?q=%@&type=all", [[NSString stringWithFormat:@"%@ - %@", tags[@"ARTIST"], tags[@"ALBUM"]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
    } else {
        url = [NSURL URLWithString:@"https://discogs.com"];
    }
    
    [self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
}

- (IBAction)releaseIdOKButtonPressed:(id)sender {
    NSAssert(self.isOnReleasePage, @"The webView must have a release's page opened!");
    
    self.releaseData = [self.dataSource tagFromDiscogsWindowController:self fetchDataForRelease:self.releaseId];
    if(!self.releaseData) return;
    
    self.headingRoles = [NSMapTable
        mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality | NSPointerFunctionsStrongMemory
        valueOptions:NSPointerFunctionsObjectPersonality | NSPointerFunctionsStrongMemory];
    
    self.fileRowsData = [NSMutableArray new];
    [self.fileRowsData addObjectsFromArray:self.files];
    [self refillFiles];
    
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
    
    [self.labelCatalogueButton removeAllItems];
    [self.labelCatalogueButton addItemWithTitle:@"[ unknown ]"];
    if(self.releaseData.catalogEntries.count > 0) {
        for (DiscogsReleaseCatalogEntry* catalogEntry in self.releaseData.catalogEntries) {
            [self.labelCatalogueButton addItemWithTitle:[NSString stringWithFormat:@"%@ / %@", catalogEntry.label, catalogEntry.catalog]];
        }
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
    DiscogsReleaseCatalogEntry* catalogEntry = nil;
    if(self.labelCatalogueButton.indexOfSelectedItem > 0) {
        catalogEntry = self.releaseData.catalogEntries[self.labelCatalogueButton.indexOfSelectedItem - 1];
    }
    // TODO
    [self.delegate tagFromDiscogsWindowController:self finishedWithPairing:nil];
}

- (void)reloadData {
    [self.discogsDataTableView reloadData];
    [self.filesTableView reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return MAX(self.releaseData.tracks.count, self.fileRowsData.count);
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if(tableView == self.discogsDataTableView){
        if(row >= self.releaseData.tracks.count){
            NSTableCellView* cell = [NSTableCellView new];
            cell.textField.stringValue = @"[ no data ]";
            return cell;
        } else {
            DiscogsReleaseTrack * track = self.releaseData.tracks[row];
            if (track.isHeading) {
                HeadingTrackTableCellView* cell = [tableView makeViewWithIdentifier:@"Heading" owner:self];
                cell.textField.stringValue = track.title;
                HeadingRole role = [([self.headingRoles objectForKey:track] ?: @(HeadingRoleDiscTitle)) integerValue];
                [cell.rolePopUpButton selectItemAtIndex:role];
                return cell;
            } else {
                NSMutableArray<NSString*>* components = [NSMutableArray new];
                if (track.position.length > 0) {
                    [components addObject:track.position];
                }
                if (track.artists.count > 0) {
                    [components addObject:[NSString stringWithFormat:@" - %@", [track.artists componentsJoinedByString:@"; "]]];
                }
                [components addObject:track.title];
                NSString* titleString = [components componentsJoinedByString:@" - "];
                if (track.subtracks.count == 0) {
                    NSTableCellView* cell = [tableView makeViewWithIdentifier:@"Track" owner:self];
                    cell.textField.stringValue = titleString;
                    return cell;
                } else {
                    IndexTrackTableCellView* cell = [tableView makeViewWithIdentifier:@"Index" owner:self];
                    cell.delegate = self;
                    cell.textField.stringValue = titleString;
                    cell.subtitleLabel.stringValue = [NSString stringWithFormat:@"%d subtracks",
                                                      (int)track.subtracks.count];
                    return cell;
                }
            }
        }
    } else if (tableView == self.filesTableView) {
        NSTableCellView* cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        if(self.fileRowsData[row] == [NSNull null]){
            cell.textField.stringValue = @"[ no file ]";
        }else{
            FileWithTags* file = self.fileRowsData[row];
            cell.textField.stringValue = file.filename.pathComponents.lastObject;
        }
        return cell;
    }else{
        NSAssert(NO, @"Invalid tableView: '%@", tableView);
        return nil;
    }
}

- (void)indexTrackTableCellViewSplit:(IndexTrackTableCellView*)view {
    NSInteger row = [self.discogsDataTableView rowForView:view];
    DiscogsReleaseTrack* track = self.releaseData.tracks[row];
    NSMutableArray* splittedTracks = [NSMutableArray new];
    [splittedTracks addObject:[[DiscogsReleaseTrack alloc] initHeadingWithTitle:track.title]];
    for (DiscogsReleaseSubtrack* subtrack in track.subtracks) {
        [splittedTracks addObject:[[DiscogsReleaseTrack alloc] initWithPosition:subtrack.position
                                                                       duration:subtrack.duration
                                                                          title:subtrack.title
                                                                        artists:subtrack.artists
                                                                      subtracks:nil]];
    }
    
    NSMutableArray* tracks = [self.releaseData.tracks mutableCopy];
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([tracks indexOfObject:track], splittedTracks.count)];
    [tracks removeObject:track];
    [tracks insertObjects:splittedTracks atIndexes:indexes];
    self.releaseData.tracks = tracks;
    [self refillFiles];
    
    [self reloadData];
}

- (void)refillFiles {
    NSMutableArray* fileRowsData = [NSMutableArray new];
    NSEnumerator* trackEnumerator = self.releaseData.tracks.objectEnumerator;
    NSEnumerator* fileEnumerator = self.fileRowsData.objectEnumerator;
    
    {
        DiscogsReleaseTrack* track;
        id fileData = fileEnumerator.nextObject;
        while ((track = trackEnumerator.nextObject) != nil && fileData != nil) {
            if (fileData != [NSNull null] && track.isHeading) {
                [fileRowsData addObject:[NSNull null]];
            } else {
                [fileRowsData addObject:fileData];
                fileData = fileEnumerator.nextObject;
            }
        }
        while (fileData != nil) {
            [fileRowsData addObject:fileData];
            fileData = fileEnumerator.nextObject;
        }
    }
    
    while (fileRowsData.count < self.releaseData.tracks.count) {
        [fileRowsData addObject:[NSNull null]];
    }
    
    self.fileRowsData = fileRowsData;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation{
    if (tableView == self.discogsDataTableView) {
        return NSDragOperationNone;
    } else {
        if(dropOperation == NSTableViewDropAbove && tableView == info.draggingSource){
            return NSDragOperationMove;
        } else {
            return NSDragOperationNone;
        }
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
    NSAssert(tableView == self.filesTableView, @"Invalid table!");
    
    NSIndexSet * indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:(NSString *)kUTTypeData]];
    NSInteger indexesLessThanTargetIndex = [indexSet countOfIndexesInRange:NSMakeRange(0, row)];
    
    NSArray * objects = [self.fileRowsData objectsAtIndexes:indexSet];
    [self.fileRowsData removeObjectsAtIndexes:indexSet];
    NSIndexSet * newIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row - indexesLessThanTargetIndex, indexSet.count)];
    [self.fileRowsData insertObjects:objects atIndexes:newIndexSet];
    [tableView selectRowIndexes:newIndexSet byExtendingSelection:NO];
    [tableView reloadData];
    
    return YES;
}

@end
