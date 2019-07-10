//
//  TagEditorWindowController.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "TagEditorWindowController.h"
#import "NSArray+FunctionalProgramming.h"

@implementation TagEditorWindowControllerResult

-(instancetype)initWithFile:(FileWithTags *)file editedTags:(NSDictionary *)editedTags{
    if (self = [super init]) {
        _file = file;
        _editedTags = editedTags;
    }
    return self;
}

@end

@interface TagEditorWindowController ()

@property (strong) IBOutlet NSWindow *addNewTagPromptWindow;
@property (weak,getter = nnewTagNameTextField) IBOutlet NSTextField *newTagNameTextField;
@property (weak,getter = nnewTagValueTextField) IBOutlet NSTextField *newTagValueTextField;

@property (weak) IBOutlet NSTableView *tableView;
@property NSArray * files;
@property NSMutableDictionary * tagsWithValues;
@property NSMutableArray * tagNames;

@property NSString * individuallyEditedTagName;
@property EditIndividualValuesWindowController * editIndividualValuesWindowController;

@end

@implementation TagEditorWindowController

-(void)dealloc{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (IBAction)editIndividualValues:(id)sender {
    if (self.tableView.clickedRow == -1) return;
    self.individuallyEditedTagName = self.tagNames[self.tableView.clickedRow];
    self.editIndividualValuesWindowController = [[EditIndividualValuesWindowController alloc] initWithWindowNibName:@"EditIndividualValuesWindowController"];
    self.editIndividualValuesWindowController.delegate = self;
    self.editIndividualValuesWindowController.dataSource = self;
    [self.editIndividualValuesWindowController refresh];
    [self.window beginSheet:self.editIndividualValuesWindowController.window completionHandler:nil];
}

-(NSArray *)filesWithTagValueForIndividualTagValueEditor:(EditIndividualValuesWindowController *)controller{
    NSMutableArray * result = [NSMutableArray new];
    NSArray * individuallyEditedTagValues = self.tagsWithValues[self.individuallyEditedTagName];
    for (int i = 0; i < self.files.count; i++) {
        FileWithIndividualTagValue * item = [[FileWithIndividualTagValue alloc] initWithFile:self.files[i] tagValue:individuallyEditedTagValues[i]];
        [result addObject:item];
    }
    return result;
}

-(void)individualTagValueEditorCancel:(EditIndividualValuesWindowController *)controller{
    [self.window endSheet:self.editIndividualValuesWindowController.window];
    self.editIndividualValuesWindowController = nil;
}

-(void)individualTagValueEditorFinished:(EditIndividualValuesWindowController *)controller withResult:(NSArray *)result{
    NSMutableArray * editedValues = [self.tagsWithValues[self.individuallyEditedTagName] mutableCopy];
    for (int i = 0; i < result.count; i++) {
        FileWithIndividualTagValue * file = result[i];
        NSUInteger index = [self.files indexOfObject:file.file];
        editedValues[index] = file.tagValue;
    }
    self.tagsWithValues[self.individuallyEditedTagName] = editedValues;
    
    [self.window endSheet:self.editIndividualValuesWindowController.window];
    self.editIndividualValuesWindowController = nil;
    
    [self.tableView reloadData];
}

-(IBAction)addNewTag:(id)sender{
    self.newTagNameTextField.stringValue = @"";
    self.newTagValueTextField.stringValue = @"";
    [self.window beginSheet:self.addNewTagPromptWindow completionHandler:nil];
}

- (IBAction)save:(id)sender {
    NSMutableArray * result = [NSMutableArray new];
    for (int i = 0; i < self.files.count; i++) {
        __block NSMutableDictionary * tags = [NSMutableDictionary new];
        [self.tagsWithValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString * tagName = key;
            NSArray * tagValues = obj;
            if (tagValues[i] != [NSNull null]) {
                tags[tagName] = tagValues[i];
            }
        }];
        [result addObject:[[TagEditorWindowControllerResult alloc] initWithFile:self.files[i] editedTags:tags]];
}
    [self.delegate tagEditorFinishedEditing:self result:result];
}

- (IBAction)cancelTagEditing:(id)sender {
    [self.delegate tagEditorCancelledEditing:self];
}

- (IBAction)newTagOkButtonDidPress:(id)sender {
    [self.window endSheet:self.addNewTagPromptWindow];
    NSString * uppercaseTagName = [self.newTagNameTextField.stringValue uppercaseString];
    if (uppercaseTagName.length > 0) {
        [self.tagNames addObject:uppercaseTagName];
        self.tagsWithValues[uppercaseTagName] = [NSArray arrayByRepeating:self.newTagValueTextField.stringValue times:self.files.count];
        [self.tableView reloadData];
    }
}

- (IBAction)newTagCancelButtonDidPress:(id)sender {
    [self.window endSheet:self.addNewTagPromptWindow];
}

-(void)refresh{
    self.files = [self.dataSource filesForTagEditorWindowController:self];
    self.tagNames = [[[[self.files map:^id(id obj) {
        FileWithTags * file = obj;
        return [file.tags allKeys];
    }] join] distinct] mutableCopy];
    self.tagsWithValues = [NSMutableDictionary new];
    for (NSString * tagName in self.tagNames) {
        self.tagsWithValues[tagName] = [self.files map:^id(id obj) {
            FileWithTags * file = obj;
            NSString * value = file.tags[tagName];
            if (value) {
                return value;
            } else {
                return [NSNull null];
            }
        }];
    }
    [self.tableView reloadData];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString * tag = self.tagNames[row];
    
    if ([tableColumn.identifier isEqualToString:@"TAG"]) {
        return tag;
    } else {
        NSArray * tagValues = self.tagsWithValues[tag];
        if ([tagValues distinct].count > 1) {
            return @"[ multiple values ]";
        } else {
            return [tagValues firstObject];
        }
    }
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.tagsWithValues.count;
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString * tag = self.tagNames[row];
    NSString * value = object;
    if ([tableColumn.identifier isEqualToString:@"TAG"]) {
        if (value.length > 0) {
            NSArray * tagValue = self.tagsWithValues[tag];
            [self.tagsWithValues removeObjectForKey:tag];
            self.tagsWithValues[[value uppercaseString]] = tagValue;
            [self.tagNames replaceObjectAtIndex:row withObject:[value uppercaseString]];
        }
    } else {
        self.tagsWithValues[tag] = [NSArray arrayByRepeating:object times:self.files.count];
    }
    [self.tableView reloadData];
}

-(void)tableViewDelete:(TableViewWithActions *)tableView{
    [self.tagsWithValues removeObjectsForKeys:[self.tagNames objectsAtIndexes:tableView.selectedRowIndexes]];
    [self.tagNames removeObjectsAtIndexes:tableView.selectedRowIndexes];
    [tableView deselectAll:self];
    [self.tableView reloadData];
}

@end
