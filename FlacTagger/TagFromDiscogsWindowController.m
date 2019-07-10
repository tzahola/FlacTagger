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

@implementation TagFromDiscogsTableViewCell
@end

@implementation DiscogsTaggingPair

-(instancetype)initWithFile:(FileWithTags *)file discogsData:(DiscogsReleaseTrack *)discogsData{
    if (self = [super init]) {
        _file = file;
        _discogsData = discogsData;
    }
    return self;
}

@end

@interface TagFromDiscogsWindowController () <WKNavigationDelegate>

@property NSColor * missingDataBackgroundColor;

@property (nonatomic, weak) IBOutlet NSTextField *albumArtistLabel;
@property (nonatomic, weak) IBOutlet NSTextField *albumTitleLabel;
@property (nonatomic, weak) IBOutlet NSTextField *releaseDateLabel;
@property (nonatomic, weak) IBOutlet NSTextField *genreLabel;

@property (nonatomic) IBOutlet NSView *releaseIdView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, weak) IBOutlet WKWebView *webView;
@property (nonatomic, readonly) BOOL isOnReleasePage;
@property (nonatomic, readonly) NSString* releaseId;
@property (nonatomic) IBOutlet NSView *discogsDataPairingView;
@property (nonatomic) NSView * emptyView;
@property (nonatomic, weak) IBOutlet SynchronizedScrollView *filesTableViewScrollView;
@property (nonatomic, weak) IBOutlet NSTableView *filesTableView;
@property (nonatomic, weak) IBOutlet SynchronizedScrollView *discogsDataTableViewScrollView;
@property (nonatomic, weak) IBOutlet NSTableView *discogsDataTableView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *labelCatalogueButton;

@property (nonatomic) DiscogsReleaseData * releaseData;
@property (nonatomic) NSArray<FileWithTags*> * files;

@property (nonatomic) NSMutableArray * trackRowsData;
@property (nonatomic) NSMutableArray * fileRowsData;

@end

@implementation TagFromDiscogsWindowController

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
    if (self.webView.URL == nil) {
        return nil;
    }

    NSString* urlString = self.webView.URL.absoluteString;
    
    NSTextCheckingResult* match = [[[self class]
        releaseIdRegexp]
        firstMatchInString:urlString
        options:0
        range:NSMakeRange(0, urlString.length)];
    if (!match || match.range.location == NSNotFound) {
        return nil;
    }
    
    return [urlString substringWithRange:[match rangeAtIndex:1]];
}

+ (NSSet *)keyPathsForValuesAffectingReleaseId {
    return [NSSet setWithObject:@"webView.URL"];
}

-(void)windowDidLoad {
    [super windowDidLoad];
    
    self.missingDataBackgroundColor = [NSColor colorWithRed:1 green:0.7 blue:0.7 alpha:1];
    
    self.emptyView = [[NSView alloc] initWithFrame:NSZeroRect];
    [self.filesTableViewScrollView setSynchronizedScrollView:self.discogsDataTableViewScrollView];
    [self.discogsDataTableViewScrollView setSynchronizedScrollView:self.filesTableViewScrollView];
    
    [self.filesTableView registerForDraggedTypes:@[ (NSString *)kUTTypeData ]];
    [self.discogsDataTableView registerForDraggedTypes:@[ (NSString *)kUTTypeData ]];
    
    self.webView.customUserAgent = kIphoneUserAgent; // force mobile version ;)
    self.webView.navigationDelegate = self;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self.progressIndicator startAnimation:nil];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.progressIndicator stopAnimation:nil];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.progressIndicator stopAnimation:nil];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
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

-(void)startWizard {
    [self.window setContentSize:self.releaseIdView.frame.size];
    self.window.contentView = self.releaseIdView;
    
    self.files = [self.dataSource tagFromDiscogsWindowControllerFiles:self];
    NSDictionary* tags = self.files[0].tags;
    NSURL* url;
    if (tags[@"ARTIST"] != nil && tags[@"ALBUM"] != nil) {
        NSURLComponents* urlComponents = [NSURLComponents componentsWithString:@"https://www.discogs.com/search/"];
        urlComponents.queryItems = @[ [NSURLQueryItem queryItemWithName:@"q" value:[NSString stringWithFormat:@"%@ - %@", tags[@"ARTIST"], tags[@"ALBUM"]]],
                                      [NSURLQueryItem queryItemWithName:@"type" value:@"master"] ];
        url = urlComponents.URL;
    } else {
        url = [NSURL URLWithString:@"https://discogs.com"];
    }
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (IBAction)releaseIdOKButtonPressed:(id)sender {
    NSAssert(self.isOnReleasePage, @"The webView must have a release's page opened!");
    
    self.releaseData = [self.dataSource tagFromDiscogsWindowController:self fetchDataForRelease:self.releaseId];
    if (!self.releaseData) return;
    
    self.trackRowsData = [NSMutableArray new];
    self.fileRowsData = [NSMutableArray new];
    NSInteger rowCount = MAX(self.releaseData.tracks.count, self.files.count);
    for (int i = 0; i < rowCount; i++) {
        if (i < self.releaseData.tracks.count) {
            [self.trackRowsData addObject:self.releaseData.tracks[i]];
        } else {
            [self.trackRowsData addObject:[NSNull null]];
        }
        
        if (i < self.files.count) {
            [self.fileRowsData addObject:self.files[i]];
        } else {
            [self.fileRowsData addObject:[NSNull null]];
        }
    }
    
    if (self.releaseData.albumArtists.count > 0) {
        self.albumArtistLabel.stringValue = [self.releaseData.albumArtists componentsJoinedByString:@", "];
    } else {
        self.albumArtistLabel.stringValue = @"[ no data ]";
    }
    
    self.albumTitleLabel.stringValue = self.releaseData.album;
    
    if (self.releaseData.releaseDate) {
        self.releaseDateLabel.stringValue = self.releaseData.releaseDate;
    } else {
        self.releaseDateLabel.stringValue = @"[ no data ]";
    }
    
    if (self.releaseData.genres.count > 0) {
        self.genreLabel.stringValue = [self.releaseData.genres componentsJoinedByString:@", "];
    } else {
        self.genreLabel.stringValue = @"[ no data ]";
    }
    
    [self.labelCatalogueButton removeAllItems];
    [self.labelCatalogueButton addItemWithTitle:@"[ unknown ]"];
    if (self.releaseData.catalogEntries.count > 0) {
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
    NSMutableArray * pairs = [NSMutableArray new];
    NSAssert(self.trackRowsData.count == self.fileRowsData.count, @"File rows count and track rows count must be equal!");
    for (int i = 0; i < self.trackRowsData.count; i++) {
        if (self.trackRowsData[i] != [NSNull null] && self.fileRowsData[i] != [NSNull null]) {
            DiscogsTaggingPair * pair = [[DiscogsTaggingPair alloc] initWithFile:self.fileRowsData[i] discogsData:self.trackRowsData[i]];
            [pairs addObject:pair];
        }
    }
    DiscogsReleaseCatalogEntry* catalogEntry = nil;
    if (self.labelCatalogueButton.indexOfSelectedItem > 0) {
        catalogEntry = self.releaseData.catalogEntries[self.labelCatalogueButton.indexOfSelectedItem - 1];
    }
    [self.delegate tagFromDiscogsWindowController:self finishedWithPairs:pairs catalogEntry:catalogEntry];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return MAX(self.releaseData.tracks.count, self.files.count);
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    TagFromDiscogsTableViewCell * cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if (tableView == self.discogsDataTableView) {
        if (self.trackRowsData[row] == [NSNull null]) {
            cell.textField.stringValue = @"[ no data ]";
        } else {
            DiscogsReleaseTrack * track = self.trackRowsData[row];
            NSString * artistsString;
            if (track.artists.count > 0) {
                artistsString = [track.artists componentsJoinedByString:@"; "];
            } else {
                artistsString = [self.releaseData.albumArtists componentsJoinedByString:@"; "];
            }
            cell.textField.stringValue = [NSString stringWithFormat:@"%@ - %@ - %@", track.position, artistsString, track.title];
        }
    } else if (tableView == self.filesTableView) {
        if (self.fileRowsData[row] == [NSNull null]) {
            cell.textField.stringValue = @"[ no file ]";
        } else {
            FileWithTags * file = self.fileRowsData[row];
            cell.textField.stringValue = [[file.filename pathComponents] lastObject];
        }
    } else {
        NSAssert(NO, @"Invalid tableView: '%@", tableView);
        return nil;
    }
    
    return cell;
}

-(void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row{
    if ((tableView == self.discogsDataTableView && self.trackRowsData[row] == [NSNull null]) ||
       (tableView == self.filesTableView && self.fileRowsData[row] == [NSNull null])) {
        rowView.backgroundColor = self.missingDataBackgroundColor;
    }
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation{
    if (dropOperation == NSTableViewDropAbove && tableView == [info draggingSource]) {
        return NSDragOperationMove;
    } else {
        return NSDragOperationNone;
    }
}

-(id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    NSIndexSet* indexes = [tableView.selectedRowIndexes containsIndex:row] ? tableView.selectedRowIndexes : [NSIndexSet indexSetWithIndex:row];

    NSError* error;
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:indexes
                                          requiringSecureCoding:NO
                                                          error:&error];
    NSAssert(data != nil, @"%@", error);

    NSPasteboardItem * result = [[NSPasteboardItem alloc] init];
    [result setData:data forType:(NSString*)kUTTypeData];

    return result;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation{
    NSError* error;
    NSIndexSet* indexSet = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSIndexSet class]
                                                             fromData:[info.draggingPasteboard dataForType:(NSString *)kUTTypeData]
                                                                error:&error];
    NSAssert(indexSet != nil, @"%@", error);

    NSInteger indexesLessThanTargetIndex = [indexSet countOfIndexesInRange:NSMakeRange(0, row)];
    
    NSMutableArray * rowData;
    if (tableView == self.filesTableView) {
        rowData = self.fileRowsData;
    } else if (tableView == self.discogsDataTableView) {
        rowData = self.trackRowsData;
    } else {
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
