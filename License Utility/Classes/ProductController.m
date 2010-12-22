//
// ProductController.m
// AquaticPrime Developer
//
// Copyright (c) 2005, Lucas Newman
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//	ﾥRedistributions of source code must retain the above copyright notice,
//	 this list of conditions and the following disclaimer.
//	ﾥRedistributions in binary form must reproduce the above copyright notice,
//	 this list of conditions and the following disclaimer in the documentation and/or
//	 other materials provided with the distribution.
//	ﾥNeither the name of the Aquatic nor the names of its contributors may be used to 
//	 endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
// IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ProductController.h"
#import "KeyController.h"
#import "LicenseController.h"
#import "AQTableView.h"

@implementation ProductController

@synthesize productArray;

#pragma mark Init

- (id)init
{
	productArray = [[[NSMutableArray alloc] init] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadProducts) name:@"NewKeyGenerated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveProducts:) name:@"NSApplicationWillTerminateNotification" object:nil];
	return [super init];
}

- (void)dealloc
{
	[productArray release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)createSupportDir
{
	NSString *mySupportDir = [licenseController supportDir];
	NSString *oldAquaticDir = [@"~/Library/Application Support/Aquatic" stringByExpandingTildeInPath];
	NSString *keyDir = [mySupportDir stringByAppendingString:@"/Product Keys"];
//	NSString *licensesDir = [mySupportDir stringByAppendingString:@"/Licenses"];
	NSString *generatedDir = [mySupportDir stringByAppendingString:@"/Generated Licenses"];
	NSString *templatesDir = [mySupportDir stringByAppendingString:@"/License Templates"];
	
	BOOL isDir;
	NSFileManager *fm = [NSFileManager defaultManager];

	if (![fm fileExistsAtPath:mySupportDir isDirectory:&isDir]) {
		[fm createDirectoryAtPath:mySupportDir attributes:nil];
		// First see if old Aquatic folder exists, if so ask to move it's content over to new folder
		// Only do this one time at this point so there are no conflicts when moving
		if ([fm fileExistsAtPath:oldAquaticDir isDirectory:&isDir])
			if (isDir) {
				NSInteger result = NSRunAlertPanel(@"Aquatic Folder Exists", [NSString stringWithFormat:@"%@ already exists as a folder. Would you like to move the contents to %@", oldAquaticDir, mySupportDir], 
												   @"Yes", @"No", nil);
				if (result == 1) {
					NSDirectoryEnumerator *pathEnum = [[NSFileManager defaultManager] enumeratorAtPath:oldAquaticDir];
					NSString *curPath;
					BOOL moved = YES;
					if(pathEnum) {
						while ((curPath = [pathEnum nextObject])) {
							NSString *source = [NSString stringWithFormat:@"%@/%@", oldAquaticDir, curPath];
							NSString *dest = [NSString stringWithFormat:@"%@/%@", mySupportDir, curPath];
							moved &= [fm movePath:source toPath:dest handler: nil];
						}
						if (moved) {
							NSRunAlertPanel(@"Aquatic Folder Transferred", 
											[NSString stringWithFormat:@"All files in %@ have been moved to %@ and the folder has been deleted", oldAquaticDir, mySupportDir], 
											@"Ok", nil, nil);
							[fm removeFileAtPath: oldAquaticDir handler: nil];
						}
						else 
							NSRunAlertPanel(@"Aquatic Folder Error", 
											[NSString stringWithFormat:@"A problem occured while moving files from %@ to %@. Please check the content manually and correct any files not moved.", oldAquaticDir, mySupportDir], 
											@"Ok", nil, nil);
					}
				}
			}
	}
	else if (!isDir) // The support path leads to a file! Bad!
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"%@ already exists as a file.  Can't create support directory.", mySupportDir], 
						@"OK", nil, nil);

	if  (![fm fileExistsAtPath:keyDir isDirectory:&isDir])
		[fm createDirectoryAtPath:keyDir attributes:nil];
	else if (!isDir) // The key directory path leads to a file! Bad again!
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"%@ already exists as a file.  Can't create key storage directory.", keyDir], 
						@"OK", nil, nil);

//	if  (![fm fileExistsAtPath:licensesDir isDirectory:&isDir])
//		[fm createDirectoryAtPath:licensesDir attributes:nil];
//	else if (!isDir) // The key directory path leads to a file! Bad again!
//		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"%@ already exists as a file.  Can't create key storage directory.", licensesDir], 
//						@"OK", nil, nil);

	if  (![fm fileExistsAtPath:generatedDir isDirectory:&isDir])
		[fm createDirectoryAtPath:generatedDir attributes:nil];
	else if (!isDir) // The key directory path leads to a file! Bad again!
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"%@ already exists as a file.  Can't create key storage directory.", generatedDir], 
						@"OK", nil, nil);

	if  (![fm fileExistsAtPath:templatesDir isDirectory:&isDir])
		[fm createDirectoryAtPath:templatesDir attributes:nil];
	else if (!isDir) // The key directory path leads to a file! Bad again!
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"%@ already exists as a file.  Can't create key storage directory.", templatesDir], 
						@"OK", nil, nil);
}

- (void)awakeFromNib
{
	[self createSupportDir];
	[self loadProducts];
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{	
	if ([[aMenuItem title] isEqualToString:@"Duplicate"] || [[aMenuItem title] isEqualToString:@"Rename"]) {
		if (![productArray count])
			return NO;
	}
	
	return YES;
}

#pragma mark Email Values
- (NSString *)emailFieldSubject {
	NSString *result = [[[keyController mailFieldsForm] cellAtIndex:0] stringValue];
	return result;
}

- (NSString *)emailFieldFrom {
	NSString *result = [[[keyController mailFieldsForm] cellAtIndex:1] stringValue];
	return result;
}

- (NSString *)emailFieldBCC {
	NSString *result = [[[keyController mailFieldsForm] cellAtIndex:2] stringValue];
	return result;
}

- (NSString *)emailLicenseTextFile {
	NSString *result = [[[keyController mailFilesForm] cellAtIndex:0] stringValue];
	return result;
}

- (NSString *)emailLicenseImageFile {
	NSString *result = [[[keyController mailFilesForm] cellAtIndex:1] stringValue];
	return result;
}

- (NSString *)emailLicenseOtherFile {
	NSString *result = [[[keyController mailFilesForm] cellAtIndex:2] stringValue];
	return result;
}


#pragma mark Load Project
- (IBAction)saveProducts:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ProductWillBeSelected" object:productTable];
}


- (void)loadProducts
{
	NSString *mySupportDir = [licenseController supportDir];
	NSString *keyDir = [mySupportDir stringByAppendingString:@"/Product Keys"];
	NSString *curPath;
	NSMutableArray *possibleproductArray = [NSMutableArray array];
	NSDirectoryEnumerator *pathEnum = [[NSFileManager defaultManager] enumeratorAtPath:keyDir];
	
	// Grab all the key paths
	if(pathEnum) {
		while ((curPath = [pathEnum nextObject])) {
			if ([[curPath pathExtension] isEqualToString:@"plist"])
				[possibleproductArray addObject:[keyDir stringByAppendingPathComponent:curPath]];
		}
	}
	
	// Determine if they are real keys
	NSEnumerator *keyEnum = [possibleproductArray objectEnumerator];
	NSString *curKey;
	NSDictionary *testDict;
	
	while ((curKey = [keyEnum nextObject])) {
		testDict = [NSDictionary dictionaryWithContentsOfFile:curKey];
		// If it has both public and private key, add it to the product list
		if ([[testDict allKeys] containsObject:@"Public Key"] && [[testDict allKeys] containsObject:@"Private Key"]) {
			if (![productArray containsObject:[[curKey lastPathComponent] stringByDeletingPathExtension]])
				[productArray addObject:[[curKey lastPathComponent] stringByDeletingPathExtension]];
			}
	}
	
	[productArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[productTable reloadData];
	
}

#pragma mark Add Project

- (IBAction)addNewProduct:(id)sender
{
	[nameField setStringValue:@"Untitled"];
	[NSApp beginSheet:newProductSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)duplicateProduct:(id)sender
{
	if (![self currentProduct])
		return;
	
	// This saves the current license template
	[self saveProducts:self];
	
	// Copy the files
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *oldProduct = [self currentProduct];
	
	// Figure out which copy we are on
	NSString *copy = @" Copy";
	int i = 1;
	while ([productArray containsObject:[oldProduct stringByAppendingString:copy]])
		copy = [NSString stringWithFormat:@" Copy %i", i++];
		
	NSString *oldTemplateProductPath = [[@"~/Library/Application Support/AquaticPrime Manager/License Templates" stringByExpandingTildeInPath] stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", oldProduct]];
	NSString *newTemplateProductPath = [[@"~/Library/Application Support/AquaticPrime Manager/License Templates" stringByExpandingTildeInPath] stringByAppendingString:[NSString stringWithFormat:@"/%@%@.plist", oldProduct, copy]];
	NSString *oldKeyProductPath = [[@"~/Library/Application Support/AquaticPrime Manager/Product Keys" stringByExpandingTildeInPath] stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", oldProduct]];
	NSString *newKeyProductPath = [[@"~/Library/Application Support/AquaticPrime Manager/Product Keys" stringByExpandingTildeInPath] stringByAppendingString:[NSString stringWithFormat:@"/%@%@.plist", oldProduct, copy]];

	[fm copyPath:oldTemplateProductPath toPath:newTemplateProductPath handler:nil];
	[fm copyPath:oldKeyProductPath toPath:newKeyProductPath handler:nil];
	
	[productArray addObject:[oldProduct stringByAppendingString:copy]];
	[productArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[productTable reloadData];
	// Select the copy
	[productTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[productArray indexOfObject:[oldProduct stringByAppendingString:copy]]]
			  byExtendingSelection:NO];
}

- (IBAction)sheetOK:(id)sender
{
	[NSApp endSheet:newProductSheet];
    [newProductSheet orderOut:self];
	
	NSString *productName = [[nameField stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([productName isEqualToString:@""])
		return;
	
	[keyController generateKeyForProduct:productName];
	if ([productArray count]) {
		[productTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[productArray indexOfObject:productName]] byExtendingSelection:NO];
		[removeProductButton setEnabled:YES];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewProductCreated" object:productName];

}

- (IBAction)sheetCancel:(id)sender
{
	[NSApp endSheet:newProductSheet];
    [newProductSheet orderOut:self];
	[nameField setStringValue:@""];
}

#pragma mark Remove Project

- (IBAction)removeProduct:(id)sender
{
	if ([productTable selectedRow] != -1)
		[productTable deleteItemAtIndex:[productTable selectedRow]];
	
	if (![productArray count])
		[removeProductButton setEnabled:NO];
}

#pragma mark Product Names

- (NSArray*)allProducts
{
	return productArray;
}

- (NSString *)currentProduct
{
	int index = [productTable selectedRow];
	
	if (index == -1)
		return nil;
	else
		return [productArray objectAtIndex:index];
}

- (NSString *)productAtIndex:(int)index
{
	if (index == -1)
		return nil;
	else
		return [productArray objectAtIndex:index];
}

- (IBAction)renameProduct:(id)sender
{
	[productTable editColumn:0 row:[productTable selectedRow] withEvent:nil select:YES];
}

#pragma mark TableView Delegate Methods
- (void)doDeleteItem:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSString *)product
{

	int index = [productArray indexOfObject:product];

	if (returnCode == NSAlertDefaultReturn) {
	NSFileManager *fm = [NSFileManager defaultManager];
		NSString *supportDir = [licenseController supportDir];
		NSError *err;
		BOOL isDir;
	
		NSString *productPath = [licenseController productPath: product];
		if ([fm fileExistsAtPath:productPath isDirectory:&isDir]) {
			[fm removeItemAtPath:productPath error:&err];
		}	
	[fm removeFileAtPath:[supportDir stringByAppendingString:[NSString stringWithFormat:@"/Product Keys/%@.plist", product]] handler:nil];
	[fm removeFileAtPath:[supportDir stringByAppendingString:[NSString stringWithFormat:@"/License Templates/%@.plist", product]] handler:nil];
		
	[productArray removeObjectAtIndex:index];
		
	[productTable reloadData];
	[productTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index-1] byExtendingSelection:NO];
	}
}

- (void)deleteItemAtIndex:(int)index
{
	NSString *product = [self productAtIndex:index];
	NSWindow *window = [productTable window];
	NSBeginAlertSheet(@"Delete Selected Product", 
					  @"Ok", 
					  @"Cancel", 
					  nil, 
					  window,
					  self, 
					  @selector(doDeleteItem:returnCode:contextInfo:), 
					  NULL, 
					  product, 
					  [NSString stringWithFormat:@"Are you sure you want to delete %@? All files will be removed! FOREVER!", product]);
//	if (NSRunAlertPanel([NSString stringWithFormat:@"Are you sure you want to delete %@?", product],
//						@"This cannot be undone.", @"OK", @"Cancel", nil) == NSAlertAlternateReturn)
		return;
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"ProductSelected" object:productTable];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [productArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [productArray objectAtIndex:row];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ProductSelected" object:aNotification];
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ProductWillBeSelected" object:tableView];
	return YES;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    // Don't allow "" as a name
	if (!object || [object isEqualToString:@""])
		return;
	
	// Move the keys to the new path
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *oldProductPath = [[@"~/Library/Application Support/AquaticPrime Manager/Product Keys" stringByExpandingTildeInPath] 
							stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", [productArray objectAtIndex:row]]];

	NSString *newProductPath = [[@"~/Library/Application Support/AquaticPrime Manager/Product Keys" stringByExpandingTildeInPath] 
							stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", object]];
	
	NSString *oldTemplateProductPath = [[@"~/Library/Application Support/AquaticPrime Manager/License Templates" stringByExpandingTildeInPath] 
										stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", [productArray objectAtIndex:row]]];

	NSString *newTemplateProductPath = [[@"~/Library/Application Support/AquaticPrime Manager/License Templates" stringByExpandingTildeInPath] 
										stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", object]];
							
	[fm movePath:oldProductPath toPath:newProductPath handler:nil];
	[fm movePath:oldTemplateProductPath toPath:newTemplateProductPath handler:nil];
	
	// Change the name
	[productArray replaceObjectAtIndex:row withObject:object];
	[productArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[productTable reloadData];
	
	// Select the renamed item
	[productTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[productArray indexOfObject:object]]
			  byExtendingSelection:NO];
}

@end
