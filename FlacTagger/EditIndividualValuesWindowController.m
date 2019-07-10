//
//  EditIndividualValuesWindowController.m
//  FlacTagger
//
//  Created by Tamás Zahola on 23/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "EditIndividualValuesWindowController.h"
#import "NSArray+FunctionalProgramming.h"

@implementation FileWithIndividualTagValue

-(instancetype)initWithFile:(FileWithTags *)file tagValue:(NSString *)tagValue{
    if (self = [super init]) {
        _file = file;
        _tagValue = tagValue;
    }
    return self;
}

@end

@interface EditIndividualValuesWindowController ()

@property NSArray * files;
@property NSMutableArray * tagValues;
@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation EditIndividualValuesWindowController

-(void)dealloc{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (IBAction)cancelButtonDidPress:(id)sender {
    [self.delegate individualTagValueEditorCancel:self];
}

- (IBAction)saveButtonDidPress:(id)sender {
    NSMutableArray * result = [NSMutableArray new];
    for (int i = 0; i < self.files.count; i++) {
        FileWithIndividualTagValue * editedFile = [[FileWithIndividualTagValue alloc] initWithFile:[self.files[i] file] tagValue:self.tagValues[i]];
        [result addObject:editedFile];
    }
    [self.delegate individualTagValueEditorFinished:self withResult:result];
}

-(void)refresh{
    self.files = [self.dataSource filesWithTagValueForIndividualTagValueEditor:self];
    self.tagValues = [[self.files map:^id(id obj) {
        FileWithIndividualTagValue * file = obj;
        return file.tagValue;
    }] mutableCopy];
    [self.tableView reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.files.count;
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    self.tagValues[row] = object;
    [tableView reloadData];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    FileWithIndividualTagValue * file = self.files[row];
    if ([tableColumn.identifier isEqualToString:@"FILE"]) {
        return [[file.file.filename pathComponents] lastObject];
    } else {
        return self.tagValues[row];
    }
}

@end
