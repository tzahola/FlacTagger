//
//  TagEditorWindowController.m
//  FlacTagger
//
//  Created by Tamás Zahola on 16/02/14.
//  Copyright (c) 2014 Tamás Zahola. All rights reserved.
//

#import "TagEditorWindowController.h"
#import "NSArray+FunctionalProgramming.h"

@interface AutocompletingTextView: NSTextView
@end

@interface AutocompletingTableRowView : NSTableRowView
@end

@implementation AutocompletingTableRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [NSColor.selectedContentBackgroundColor setFill];
    NSRectFill(self.bounds);
}

@end

@interface AutocompletingTextViewPopoverViewController: NSViewController <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) NSArray<NSString*>* completions;
@property (nonatomic) NSInteger selectedIndex;

@end

@interface AutocompletingTextView ()

- (void)didSelectCompletion:(BOOL)isFinal;

@end

@implementation AutocompletingTextViewPopoverViewController {
    NSTableView* _tableView;
    BOOL _selectingRowProgrammatically;
    __weak AutocompletingTextView* _textView;
}

- (instancetype)initWithTextView:(AutocompletingTextView*)textView
                     completions:(NSArray<NSString*>*)completions {
    if (self = [super init]) {
        _textView = textView;
        _completions = [completions copy];
    }
    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSZeroRect];
    
    _tableView = [[NSTableView alloc] initWithFrame:self.view.bounds];
    _tableView.refusesFirstResponder = YES;
    _tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView addTableColumn:[[NSTableColumn alloc] initWithIdentifier:@"COMPLETION"]];
    _tableView.target = self;
    _tableView.action = @selector(didSelectCompletion);
    _tableView.doubleAction = @selector(didSelectFinalCompletion);
    
    [self.view addSubview:_tableView];
    
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [_tableView.widthAnchor constraintEqualToConstant:150],
    ]];
}

- (void)setCompletions:(NSArray<NSString *> *)completions {
    _completions = [completions copy];
    [_tableView reloadData];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    _selectingRowProgrammatically = YES;
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
    _selectingRowProgrammatically = NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _completions.count;
}

- (NSView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[AutocompletingTableRowView alloc] initWithFrame:NSZeroRect];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [NSTextField labelWithString:_completions[row]];
}

- (void)didSelectCompletion {
    [self didSelectCompletion:NO];
}

- (void)didSelectFinalCompletion {
    [self didSelectCompletion:YES];
}

- (void)didSelectCompletion:(BOOL)isFinal {
    _selectedIndex = _tableView.selectedRow;
    [_textView didSelectCompletion:isFinal];
}

@end

@implementation AutocompletingTextView {
    AutocompletingTextViewPopoverViewController* _autocompleteViewController;
    NSPopover* _autocompletePopover;
    BOOL _keepAutocompleteOnSelectionChange;
    NSArray<NSString*>* _completions;
    NSRange _completionRange;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self doCommonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container {
    if (self = [super initWithFrame:frameRect textContainer:container]) {
        [self doCommonInit];
    }
    return self;
}

- (void)doCommonInit {
    __weak AutocompletingTextView* weakSelf = self;
    [NSNotificationCenter.defaultCenter addObserverForName:NSApplicationDidResignActiveNotification
                                                    object:NSApp
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull note) {
        AutocompletingTextView* strongSelf = weakSelf;
        if (!strongSelf || !strongSelf->_autocompletePopover) {
            return;
        }
        [strongSelf insertCompletion:@""
                 forPartialWordRange:strongSelf->_completionRange
                            movement:NSTextMovementCancel
                             isFinal:YES];
        [strongSelf dismissAutocompletePopover];
    }];
}

- (void)insertText:(id)string replacementRange:(NSRange)replacementRange {
    _keepAutocompleteOnSelectionChange = YES;
    [super insertText:string replacementRange:replacementRange];
    _keepAutocompleteOnSelectionChange = NO;
    
    [self complete:nil];
}

- (void)dismissAutocompletePopover {
    if (_autocompletePopover) {
        [_autocompletePopover close];
        _autocompletePopover = nil;
    }
}

- (void)setSelectedRange:(NSRange)charRange
                affinity:(NSSelectionAffinity)affinity
          stillSelecting:(BOOL)stillSelectingFlag {
    [super setSelectedRange:charRange affinity:affinity stillSelecting:stillSelectingFlag];
    if (!_keepAutocompleteOnSelectionChange) {
        [self dismissAutocompletePopover];
    }
}

- (void)cancelOperation:(id)sender {
    if (_autocompletePopover) {
        [self dismissAutocompletePopover];
        [self delete:sender];
    } else {
        [self.nextResponder tryToPerform:_cmd with:sender];
    }
}

- (void)moveUp:(id)sender {
    if (_autocompletePopover) {
        if (_autocompleteViewController.selectedIndex >= 0) {
            _autocompleteViewController.selectedIndex = MAX(0, _autocompleteViewController.selectedIndex - 1);
        }
        [self insertCompletionWithMovement:NSTextMovementUp isFinal:NO];
    } else {
        [super moveUp:sender];
    }
}

- (void)moveDown:(id)sender {
    if (_autocompletePopover) {
        if (_autocompleteViewController.selectedIndex < 0) {
            _autocompleteViewController.selectedIndex = 0;
        } else {
            _autocompleteViewController.selectedIndex = MIN(_completions.count - 1, _autocompleteViewController.selectedIndex + 1);
        }
        [self insertCompletionWithMovement:NSTextMovementDown isFinal:NO];
    } else {
        [super moveDown:sender];
    }
}

- (void)insertNewline:(id)sender {
    if (_autocompletePopover) {
        [self insertCompletionWithMovement:NSTextMovementReturn isFinal:YES];
        [self dismissAutocompletePopover];
    } else {
        [super insertNewline:sender];
    }
}

- (void)insertTab:(id)sender {
    if (_autocompletePopover) {
        [self insertCompletionWithMovement:NSTextMovementTab isFinal:YES];
        [self dismissAutocompletePopover];
    } else {
        [super insertTab:sender];
    }
}

- (void)didSelectCompletion:(BOOL)isFinal {
    [self insertCompletionWithMovement:NSTextMovementOther isFinal:isFinal];
    if (isFinal) {
        self.selectedRange = NSMakeRange(self.selectedRange.location + self.selectedRange.length, 0);
        [self dismissAutocompletePopover];
    }
}

- (void)insertCompletionWithMovement:(NSTextMovement)movement isFinal:(BOOL)isFinal {
    _keepAutocompleteOnSelectionChange = YES;
    if (_autocompleteViewController.selectedIndex >= 0) {
        NSString* completion = _completions[_autocompleteViewController.selectedIndex];
        [self insertCompletion:completion forPartialWordRange:_completionRange movement:movement isFinal:isFinal];
    }
    _keepAutocompleteOnSelectionChange = NO;
}

- (void)complete:(id)sender {
    _completionRange = self.rangeForUserCompletion;

    NSInteger selected;
    _completions = [self completionsForPartialWordRange:_completionRange
                                    indexOfSelectedItem:&selected];
    if (_completions.count == 0) {
        [self dismissAutocompletePopover];
        return;
    }

    NSRange completionGlyphRange = [self.layoutManager glyphRangeForCharacterRange:_completionRange actualCharacterRange:nil];
    NSRect rect = [self.layoutManager boundingRectForGlyphRange:completionGlyphRange inTextContainer:self.textContainer];

    if (!_autocompletePopover) {
        _autocompleteViewController = [[AutocompletingTextViewPopoverViewController alloc] initWithTextView:self
                                                                                                completions:_completions];
        _autocompletePopover = [[NSPopover alloc] init];
        _autocompletePopover.contentViewController = _autocompleteViewController;
    } else {
        _autocompleteViewController.completions = _completions;
    }

    [_autocompletePopover showRelativeToRect:rect ofView:self preferredEdge:NSRectEdgeMaxY];

    _autocompleteViewController.selectedIndex = selected;
    if (selected >= 0) {
        [self insertCompletionWithMovement:NSTextMovementOther isFinal:NO];
    }
}

- (BOOL)resignFirstResponder {
    BOOL didResign = [super resignFirstResponder];
    if (didResign) {
        [self dismissAutocompletePopover];
    }
    return didResign;
}

@end

@implementation TagEditorWindowControllerResult

-(instancetype)initWithFile:(FileWithTags *)file editedTags:(NSDictionary *)editedTags{
    if (self = [super init]) {
        _file = file;
        _editedTags = editedTags;
    }
    return self;
}

@end

@interface TagEditorWindowController () <NSComboBoxDelegate, NSTextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSWindow *addNewTagWindow;
@property (nonatomic, weak) IBOutlet NSComboBox *addedTagNameComboBox;
@property (nonatomic, weak) IBOutlet NSTextField *addedTagValueTextField;

@property (weak) IBOutlet NSTableView *tableView;
@property NSArray * files;
@property NSMutableDictionary * tagsWithValues;
@property NSMutableArray<NSString*> * tagNames;
@property BOOL isCompletingTagValue;

@property NSString * individuallyEditedTagName;
@property EditIndividualValuesWindowController * editIndividualValuesWindowController;

@end

@implementation TagEditorWindowController

-(void)dealloc{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (IBAction)edit:(id)sender {
    NSInteger row = self.tableView.clickedRow;
    if (row == -1) {
        row = self.tableView.selectedRow;
    }
    if (row == -1) {
        return;
    }
    
    self.individuallyEditedTagName = self.tagNames[row];
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

-(IBAction)addNewTag:(id)sender {
    NSArray* objects;
    BOOL didLoad = [[[NSNib alloc] initWithNibNamed:@"AddNewTagWindow" bundle:nil]
                    instantiateWithOwner:self
                    topLevelObjects:&objects];
    NSAssert(didLoad, @"");
    
    [self.addedTagNameComboBox addItemsWithObjectValues:@[
        @"ALBUM",
        @"ALBUMARTIST",
        @"ARTIST",
        @"CATALOG",
        @"DATE",
        @"DISCNUMBER",
        @"DISCSUBTITLE",
        @"DISCTOTAL",
        @"EDITION",
        @"GENRE",
        @"LABEL",
        @"ORIGINALDATE",
        @"TITLE",
        @"TRACKNUMBER",
        @"TRACKTOTAL",
    ]];
    
    [self.addNewTagWindow makeFirstResponder:self.addedTagNameComboBox];
    [self.window beginSheet:self.addNewTagWindow completionHandler:nil];
}

- (IBAction)save:(id)sender {
    [self.window makeFirstResponder:nil];
    
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
    [self.window.attachedSheet makeFirstResponder:nil];
    [self.window endSheet:self.window.attachedSheet];
    NSString * uppercaseTagName = [self.addedTagNameComboBox.stringValue uppercaseString];
    if (uppercaseTagName.length > 0) {
        [self.tagNames addObject:uppercaseTagName];
        self.tagsWithValues[uppercaseTagName] = [NSArray arrayByRepeating:self.addedTagValueTextField.stringValue times:self.files.count];
        [self.tableView reloadData];
    }
}

- (IBAction)newTagCancelButtonDidPress:(id)sender {
    [self.window endSheet:self.window.attachedSheet];
}

-(void)refresh {
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

- (NSArray<NSString *> *)control:(NSControl *)control
                        textView:(NSTextView *)textView
                     completions:(NSArray<NSString *> *)words
             forPartialWordRange:(NSRange)charRange
             indexOfSelectedItem:(NSInteger *)index {
    if ((control == self.addedTagValueTextField &&
         [self.addedTagNameComboBox.stringValue.uppercaseString isEqual:@"GENRE"]) ||
        (control == self.tableView &&
         [self.tableView.tableColumns[self.tableView.editedColumn].identifier isEqualToString:@"VALUE"] &&
         [self.tagNames[self.tableView.editedRow].uppercaseString isEqualToString:@"GENRE"])) {
        
        static NSArray<NSString*>* genres;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            genres = @[
                @"Electronic", @"House", @"Deep House", @"Disco", @"Drum n Bass", @"Jazz",
                @"Free Jazz", @"Jungle", @"Juke", @"Dub", @"Dub Techno", @"Ambient", @"Acid",
                @"Bass Music", @"Dubstep", @"Grime", @"Electro", @"Funk / Soul", @"Hardcore",
                @"Rock", @"Indie Rock", @"Krautrock", @"Leftfield", @"Lo-Fi House", @"Microhouse",
                @"New Age", @"Psychedelic Rock", @"Rave", @"Shoegaze", @"Synthwave", @"Tribal",
                @"Tribal Ambient", @"Tribal House", @"UK Garage", @"Garage", @"World", @"Afrobeat",
                @"Alternative Rock", @"Techno", @"Minimal Techno", @"Tech House", @"Trance",
                @"Chillout", @"Classical", @"Glitch", @"Hip Hop", @"Downtempo", @"Experimental",
                @"IDM", @"Breakbeat", @"Fusion", @"Trip Hop", @"New Age", @"Abstract", @"Drone"
            ];
        });
        
        NSString* string = [textView.string substringWithRange:charRange];
        return [genres filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* g, id _) {
            return [g hasPrefix:string];
        }]];
    }
    return nil;
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client {
    if (client == self.tableView || client == self.addedTagValueTextField) {
        AutocompletingTextView* textView = [[AutocompletingTextView alloc] init];
        textView.fieldEditor = YES;
        return textView;
    }
    return nil;
}

@end
