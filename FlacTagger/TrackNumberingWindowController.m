//
//  TrackNumberingWindowController.m
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "TrackNumberingWindowController.h"

@implementation TrackNumberingResult

-(instancetype)initWithFile:(FileWithTags *)file
                 discNumber:(NSInteger)discNumber
                trackNumber:(NSInteger)trackNumber
                  discTotal:(NSInteger)discTotal
                 trackTotal:(NSInteger)trackTotal{
    if(self = [super init]){
        _file = file;
        _discNumber = discNumber;
        _trackNumber = trackNumber;
        _discTotal = discTotal;
        _trackTotal = trackTotal;
    }
    return self;
}

@end

@interface TrackNumberingWindowController ()

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *trackNumberingPatternTextField;

@property NSArray * files;
@property NSMutableArray * trackNumbers;
@property NSMutableArray * trackTotals;
@property NSMutableArray * discNumbers;
@property NSInteger discTotal;

@end

@implementation TrackNumberingWindowController

-(void)windowDidLoad{
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(patternDidChange:) name:NSControlTextDidChangeNotification object:self.trackNumberingPatternTextField];
    [self refresh];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

-(void)patternDidChange:(NSNotification*)notification{
    [self rebuildTrackNumbers];
}

-(void)refresh{
    self.files = [self.dataSource filesForTrackNumberingWindowController:self];
    self.trackNumberingPatternTextField.stringValue = [NSString stringWithFormat:@"%d", (int)self.files.count];
    [self rebuildTrackNumbers];
}

-(void)rebuildTrackNumbers{
    NSArray * discLengths = [self.trackNumberingPatternTextField.stringValue componentsSeparatedByString:@","];
    NSMutableArray * discLengthNumbers = [NSMutableArray new];
    
    NSInteger sum = 0;
    for(NSString * stringLength in discLengths){
        NSInteger integerLength = [stringLength integerValue];
        if(integerLength > 0){
            sum += integerLength;
            [discLengthNumbers addObject:@(integerLength)];
        }
    }
    
    if(sum == self.files.count){
        self.discTotal = discLengthNumbers.count;
        self.trackNumbers = [NSMutableArray new];
        self.trackTotals = [NSMutableArray new];
        self.discNumbers = [NSMutableArray new];
        
        for(int j = 0; j < discLengthNumbers.count; j++){
            for(int i = 0; i < [discLengthNumbers[j] integerValue]; i++){
                [self.trackTotals addObject:discLengthNumbers[j]];
                [self.trackNumbers addObject:@(i+1)];
                [self.discNumbers addObject:@(j+1)];
            }
        }
        [self.tableView reloadData];
    }
}

- (IBAction)okButtonDidPress:(id)sender {
    NSMutableArray * results = [NSMutableArray new];
    for(int i = 0; i < self.files.count; i++){
        TrackNumberingResult * result = [[TrackNumberingResult alloc] initWithFile:self.files[i]
                                                                        discNumber:[self.discNumbers[i] integerValue]
                                                                       trackNumber:[self.trackNumbers[i] integerValue]
                                                                         discTotal:self.discTotal
                                                                        trackTotal:[self.trackTotals[i] integerValue]];
        [results addObject:result];
    }
    [self.delegate trackNumberingWindowController:self finishedWithResults:results];
}

- (IBAction)cancelButtonDidPress:(id)sender {
    [self.delegate trackNumberingWindowControllerDidCancel:self];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.files.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    
    FileWithTags * file = self.files[row];
    
    if([tableColumn.identifier isEqualToString:@"DISCNUMBER"]){
        return [NSString stringWithFormat:@"%@ / %d", self.discNumbers[row], (int)self.discTotal];
    }else if([tableColumn.identifier isEqualToString:@"TRACKNUMBER"]){
        return [NSString stringWithFormat:@"%@ / %@", self.trackNumbers[row], self.trackTotals[row]];
    }else if([tableColumn.identifier isEqualToString:@"ARTIST"]){
        return file.tags[@"ARTIST"];
    }else if([tableColumn.identifier isEqualToString:@"TITLE"]){
        return file.tags[@"TITLE"];
    }else{
        NSAssert(NO, @"Invalid column: '%@'", tableColumn);
        return nil;
    }
}

-(BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView{
    return NO;
}

@end
