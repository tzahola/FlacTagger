//
//  FileRenamingWindowController.m
//  FlacTagger
//
//  Created by Tamás Zahola on 08/03/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "FileRenamingWindowController.h"
#import <objc/runtime.h>

@implementation FileRenaming

-(instancetype)initWithFile:(FileWithTags *)file newFileName:(NSString *)newFileName{
    if (self = [super init]) {
        _file = file;
        _newFileName = newFileName;
    }
    return self;
}

@end

@interface FileRenamingWindowController ()

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *fileNamePatternTextField;

@property NSArray * files;
@property NSMutableArray * renamedFileNames;

@end

@implementation FileRenamingWindowController

- (IBAction)okButtonDidPress:(id)sender {
    NSMutableArray * renamings = [NSMutableArray new];
    for (int i = 0; i < self.files.count; i++) {
        FileWithTags * file = self.files[i];
        NSString * newFileName = self.renamedFileNames[i];
        FileRenaming * renaming = [[FileRenaming alloc] initWithFile:file newFileName:newFileName];
        [renamings addObject:renaming];
    }
    [self.delegate fileRenamingWindowController:self renameFiles:renamings];
}

- (IBAction)cancelButtonDidPress:(id)sender {
    [self.delegate fileRenamingWindowControllerCancel:self];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    self.fileNamePatternTextField.stringValue = @"%tracknumber% - %artist% - %title%";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(patternDidChange:) name:NSControlTextDidChangeNotification object:self.fileNamePatternTextField];
    [self refresh];
}

-(void)dealloc{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)patternDidChange:(NSNotification*)notification{
    [self refresh];
}

-(void)refresh{
    self.files = [self.dataSource filesForFileRenamingWindowController:self];
    NSInteger maxTracknumberLength = 0;
    NSInteger maxDiscnumberLength = 0;
    for (FileWithTags * file in self.files) {
        maxTracknumberLength = MAX([file.tags[@"TRACKNUMBER"] length], maxTracknumberLength);
        maxDiscnumberLength = MAX([file.tags[@"DISCNUMBER"] length], maxDiscnumberLength);
    }
    
    self.renamedFileNames = [NSMutableArray new];
    for (FileWithTags * file in self.files) {
        NSMutableString * newFileName = [self.fileNamePatternTextField.stringValue mutableCopy];
        [newFileName replaceOccurrencesOfString:@"%artist%" withString:[self emptyIfNil:file.tags[@"ARTIST"]] options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"%title%" withString:[self emptyIfNil:file.tags[@"TITLE"]] options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"%album%" withString:[self emptyIfNil:file.tags[@"ALBUM"]] options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"%tracknumber%" withString:[self padLeft:[self emptyIfNil:file.tags[@"TRACKNUMBER"]] withString:@"0" toLength:maxTracknumberLength] options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"%discnumber%" withString:[self padLeft:[self emptyIfNil:file.tags[@"DISCNUMBER"]] withString:@"0" toLength:maxDiscnumberLength] options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"%tracktotal%" withString:[self emptyIfNil:file.tags[@"TRACKTOTAL"]] options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"%disctotal%" withString:[self emptyIfNil:file.tags[@"DISCTOTAL"]] options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"%albumartist%" withString:[self emptyIfNil:file.tags[@"ALBUMARTIST"]] options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"/" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@":" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"?" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"\\" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName replaceOccurrencesOfString:@"|" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, newFileName.length)];
        [newFileName appendFormat:@".%@",file.filename.pathExtension];
        [self.renamedFileNames addObject:[newFileName stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                          locale:[NSLocale localeWithLocaleIdentifier:@"en_US"]]];
    }
    
    [self.tableView reloadData];
}

-(NSString*)emptyIfNil:(NSString*)value{
    if (value) {
        return value;
    } else {
        return @"";
    }
}

-(NSString*)padLeft:(NSString*)string withString:(NSString*)padding toLength:(NSInteger)length{
    return [[@"" stringByPaddingToLength:length-string.length withString:padding startingAtIndex:0] stringByAppendingString:string];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.files.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return self.renamedFileNames[row];
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row{
    return NO;
}

@end
