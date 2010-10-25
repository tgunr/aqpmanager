//
// LicenseController.m
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

#import "LicenseController.h"
#import "MainController.h"
#import "KeyController.h"
#import "StatusController.h"
#import "ProductController.h"
#import "AquaticPrime.h"
#import "AQTableView.h"

@implementation LicenseController

#pragma mark Init

- (id)init
{
	keyArray = [[NSMutableArray array] retain];
	valueArray = [[NSMutableArray array] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newProductSelected) name:@"ProductSelected" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveLicenseTemplate:) name:@"ProductWillBeSelected" object:nil];
	
	return [super init];
}
 
- (void)dealloc
{
	[keyArray release];
	[valueArray release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)awakeFromNib {

}

#pragma mark License Generation

- (void) completeTableEntry 
{
	// If a column is selected ensure it is completed
	NSInteger sr = [keyValueTable selectedRow];
	if (sr != -1) {
		[keyValueTable deselectRow:sr];
	}
}

- (IBAction)generateLicense:(id)sender
{
	NSString *errorString;
	
	if ([keyArray count] == 0) {
		errorString = @"Please assign at least one key-value pair.";
		NSRunAlertPanel(@"Could not create license file", errorString, @"OK", nil, nil);
		return;
	}
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *supportDir = [@"~/Library/Application Support/Aquatic" stringByExpandingTildeInPath];
	NSString *licenseDir = [supportDir stringByAppendingString:@"/Generated Licenses"];
	BOOL isDir;
	
	// The ~/Library/Application Support/Aquatic/ folder doesn't exist yet
	if (![fm fileExistsAtPath:supportDir isDirectory:&isDir])
	{
		// The support path leads to a file! Bad! This shouldn't happen ever!!
		if (!isDir)
			[fm removeFileAtPath:supportDir handler:nil];
		
		// Create the ~/Library/Application Support/Aquatic/ directory
		[fm createDirectoryAtPath:supportDir attributes:nil];
	}

	// The ~/Library/Application Support/Aquatic/Generated Licenses folder doesn't exist yet
	if  (![fm fileExistsAtPath:licenseDir isDirectory:&isDir])
	{
		// The licenses path leads to a file! Bad! This shouldn't happen ever!!
		if (!isDir)
			[fm removeFileAtPath:licenseDir handler:nil];
			
		// Create the product key directory
		[fm createDirectoryAtPath:licenseDir attributes:nil];
	}
	
	licenseDictionary = [NSMutableDictionary dictionaryWithObjects:valueArray forKeys:keyArray];
	
	NSString *publicKey = [keyController publicKey];
	NSString *privateKey = [keyController privateKey];
	
	if (!publicKey || !privateKey)
		return;
	
	[self completeTableEntry];

	licenseMaker = [AquaticPrime aquaticPrimeWithKey:publicKey privateKey:privateKey];
	
	NSString *path = [NSString stringWithFormat:@"%@/Licenses/%@.%@", [saveDirectoryField stringValue], [valueArray objectAtIndex:0], [licenseExtensionField stringValue]];
	NSString *backupPath = [NSString stringWithFormat:@"%@/%@.%@", licenseDir, [valueArray objectAtIndex:0], [licenseExtensionField stringValue]];
	[licenseMaker writeLicenseFileForDictionary:licenseDictionary toPath:path];
	[licenseMaker writeLicenseFileForDictionary:licenseDictionary toPath:backupPath];
	[statusController setStatus:[NSString stringWithFormat:@"Wrote license to %@", path] duration:5.0];
	
	//	BOOL useMySQL = [[NSUserDefaults standardUserDefaults] objectForKey:@"MYSQLUse"];
	//	if (useMySQL)
	//		[self insertMySQL: sender];

}
 
#pragma mark Saving & Loading License Templates

- (void)saveLicenseTemplate:(id)anObject
{	
	// Make sure the object is a tableView
	int index;
	if ([anObject respondsToSelector:@selector(object)] && [[anObject object] respondsToSelector:@selector(selectedRow)]) {
		index = [[anObject object] selectedRow];
		if (index == -1) {
			return;	
		}		
	}
	else
		return;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *supportDir = [@"~/Library/Application Support/Aquatic" stringByExpandingTildeInPath];
	NSString *templateDir = [supportDir stringByAppendingString:@"/License Templates"];
	NSString *productPath = [templateDir stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", [productController productAtIndex:index]]];
	BOOL isDir;
	
	// Save this way to preserve the order of items
	NSDictionary *templateDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  [productController productAtIndex:index], @"Product",
								  keyArray, @"Keys", 
								  valueArray, @"Values", 
								  [licenseExtensionField stringValue], @"Extension",
								  [saveDirectoryField stringValue], @"Save Directory", 
								  emailKey, @"EmailKey",
								  nil];
	
	// The ~/Library/Application Support/Aquatic/ folder doesn't exist yet
	if (![fm fileExistsAtPath:supportDir isDirectory:&isDir])
	{
		// The support path leads to a file! Bad! This shouldn't happen ever!!
		if (!isDir)
			[fm removeFileAtPath:supportDir handler:nil];
		
		// Create the ~/Library/Application Support/Aquatic/ directory
		[fm createDirectoryAtPath:supportDir attributes:nil];
	}
	
	// The ~/Library/Application Support/Aquatic/License Templates folder doesn't exist yet
	if  (![fm fileExistsAtPath:templateDir isDirectory:&isDir])
	{
		// The template path leads to a file! Bad! This shouldn't happen ever!!
		if (!isDir)
			[fm removeFileAtPath:templateDir handler:nil];
			
		// Create the product key directory
		[fm createDirectoryAtPath:templateDir attributes:nil];
	}
	
	[templateDict writeToFile:productPath atomically:YES];

	return;
}
 
- (BOOL)loadLicenseTemplate
{
	if (![productController currentProduct])
		return NO;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *supportDir = [@"~/Library/Application Support/Aquatic" stringByExpandingTildeInPath];
	NSString *templateDir = [supportDir stringByAppendingString:@"/License Templates"];
	NSString *productPath = [templateDir stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", [productController currentProduct]]];

	if (![fm fileExistsAtPath:productPath])
	{
		[licenseExtensionField setStringValue:@"plist"];
		[licenseExtensionEditField setStringValue:@"plist"];
		[saveDirectoryField setStringValue:[@"~/Documents" stringByExpandingTildeInPath]];
		return NO;
	}
	
	NSDictionary *templateDict = [NSDictionary dictionaryWithContentsOfFile:productPath];
	application = [[templateDict objectForKey:@"Product"] retain];
	keyArray = [[NSMutableArray arrayWithArray:[templateDict objectForKey:@"Keys"]] retain];
	valueArray = [[NSMutableArray arrayWithArray:[templateDict objectForKey:@"Values"]] retain];
	[licenseExtensionField setStringValue:[templateDict objectForKey:@"Extension"]];
	[saveDirectoryField setStringValue:[templateDict objectForKey:@"Save Directory"]];
	
	emailKey = [templateDict objectForKey:@"EmailKey"];
	if ([emailKey length]) 
		emailAddress = [valueArray objectAtIndex:[keyArray indexOfObject:emailKey]];
	else {
		emailAddress = @"";
		emailKey = @"";
	}

	[licenseEmailField setStringValue:emailKey];
	
	
	
	if (![keyArray count])
		[generateLicenseButton setEnabled:NO];
	if ([emailAddress length])
		[emailButton setEnabled:YES];
	else
		[emailButton setEnabled:NO];
	return YES;
}

#pragma mark Product Selection

- (void)newProductSelected
{
	if (keyArray)
		[keyArray release];
	if (valueArray)
		[valueArray release];
		
	// Enable everything except the remove button
	[addButton setEnabled:YES];
	[generateLicenseButton setEnabled:YES];
	[editExtensionButton setEnabled:YES];
	[editSaveDirectoryButton setEnabled:YES];
		
	// No template and a product, i.e. new product
	if (![self loadLicenseTemplate] && [productController currentProduct]) {
		// Default values
		keyArray = [[NSMutableArray arrayWithObjects:@"Name", @"Email", nil] retain];
		valueArray = [[NSMutableArray arrayWithObjects:@"User", @"user@email.com", nil] retain];
	}
	// No product
	else if (![productController currentProduct] ) {
		// Disable everything
		[addButton setEnabled:NO];
		[removeButton setEnabled:NO];
		[generateLicenseButton setEnabled:NO];
		[editExtensionButton setEnabled:NO];
		[editSaveDirectoryButton setEnabled:NO];
		[emailButton setEnabled:NO];
		
		[licenseExtensionField setStringValue:@""];
		[saveDirectoryField setStringValue:@""];
		[licenseEmailField setStringValue:@""];
		
		keyArray = [[NSMutableArray array] retain];
		valueArray = [[NSMutableArray array] retain];
	}
	
	[keyValueTable reloadData];
}

#pragma mark Interface

- (IBAction)editLicenseExtension:(id)sender
{
	[licenseExtensionEditField setStringValue:[licenseExtensionField stringValue]];
	[NSApp beginSheet:licenseExtensionSheet modalForWindow:[NSApp keyWindow]
		   modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (BOOL) foldersExist: (id)sender {
	BOOL aDir;
	BOOL folderExists;
	int result = 0; // if this is ever non zero, something went haywire
	NSString *mkdirString;
	NSString *folderPath;
	
	NSFileManager *fm = [NSFileManager defaultManager];

	folderPath = [NSString stringWithFormat: @"%@", [saveDirectoryField stringValue]];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@", [saveDirectoryField stringValue]];
		result = system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}

	folderPath = [NSString stringWithFormat: @"%@/Attachments", [saveDirectoryField stringValue]];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Attachments", [saveDirectoryField stringValue]];
		result += system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}

	folderPath = [NSString stringWithFormat: @"%@/Licenses", [saveDirectoryField stringValue]];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Licenses", [saveDirectoryField stringValue]];
		result += system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}
	folderPath = [NSString stringWithFormat: @"%@/Blacklist", [saveDirectoryField stringValue]];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Blacklist", [saveDirectoryField stringValue]];
		result += system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}
	
	if (result == 0) 
		NSBeginInformationalAlertSheet(@"Storage folders",
									   @"OK",
									   nil,
									   nil,
									   [sender window],               // window sheet is attached to
									   self,                   // we'll be our own delegate
									   nil,
									   nil,                   // no need for did-dismiss selector
									   nil,
									   @"The auxiliary folders Attachments, Licenses, and Blacklist exist at \n%@",
									   [saveDirectoryField stringValue]
									   );                   // no parameters in message
	else {
		NSBeginCriticalAlertSheet(@"Storage folders",
									   @"OK",
									   nil,
									   nil,
									   [sender window],               // window sheet is attached to
									   self,                   // we'll be our own delegate
									   nil,
									   nil,                   // no need for did-dismiss selector
									   nil,
									   @"One of auxiliary folders Attachments, Licenses, or Blacklist has NOT been created at \n%@\n Check for correct permissions or other problems that may casue a failure to create folders.",
									   [saveDirectoryField stringValue]
									   );                   // no parameters in message
		[saveDirectoryField setStringValue:@"ERROR! Folders not created"];

	}
	return result == 0;
}

- (IBAction)editSaveDirectory:(id)sender
{
	// Run the selection panel
	NSOpenPanel *selectPanel = [NSOpenPanel openPanel];
	[selectPanel setCanChooseFiles:NO];
	[selectPanel setCanChooseDirectories:YES];
	[selectPanel setCanCreateDirectories: YES];
	[selectPanel setAllowsMultipleSelection:NO];
	[selectPanel setPrompt:@"Select"];
	[selectPanel setTitle:@"Select Directory"];
	if ([selectPanel runModal] == NSFileHandlingPanelCancelButton)
		return;
	
	NSString *saveFolder = [[selectPanel filenames] objectAtIndex:0];
	[saveDirectoryField setStringValue:saveFolder];
	
	[self foldersExist: sender];
//	APPKIT_EXTERN void NSBeginInformationalAlertSheet(NSString *title, 
//													  NSString *defaultButton, 
//													  NSString *alternateButton, 
//													  NSString *otherButton, 
//													  NSWindow *docWindow, 
//													  id modalDelegate, 
//													  SEL didEndSelector, 
//													  SEL didDismissSelector, 
//													  void *contextInfo, 
//													  NSString *msgFormat, ...);
}

- (IBAction)sheetOK:(id)sender
{
	[NSApp endSheet:licenseExtensionSheet];
    [licenseExtensionSheet orderOut:self];
	
	[licenseExtensionField setStringValue:[licenseExtensionEditField stringValue]];
}

- (IBAction)sheetCancel:(id)sender
{
	[NSApp endSheet:licenseExtensionSheet];
    [licenseExtensionSheet orderOut:self];
}

- (IBAction)addKeyValue:(id)sender
{
	[keyArray addObject:@"New Key"];
	[valueArray addObject:@"Undefined"];
	
	[keyValueTable reloadData];
	
	[generateLicenseButton setEnabled:YES];
}

- (IBAction)removeKeyValue:(id)sender
{
	if ([keyValueTable selectedRow] == -1)
		return;
	else
		[keyValueTable deleteItemAtIndex:[keyValueTable selectedRow]];
}

#pragma mark TableView Delegate Methods

- (void)deleteItemAtIndex:(int)row
{
	[keyArray removeObjectAtIndex:row];
	[valueArray removeObjectAtIndex:row];
	
	// Make sure we don't lose a reference to the arrays
	if (![keyArray count])
		[keyArray retain];
	if (![valueArray count])
		[valueArray retain];
	
	[keyValueTable reloadData];
	[keyValueTable selectRow:row-1 byExtendingSelection:NO];
	
	if (![keyArray count])
		[generateLicenseButton setEnabled:NO];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if ([keyArray count] <= [valueArray count])
		return [keyArray count];
	else
		return [valueArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if ([[tableColumn identifier] isEqualToString:@"keyColumn"])
		return [keyArray objectAtIndex:row];
	else
		return [valueArray objectAtIndex:row];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if (!object)
		return;
		
	if ([[tableColumn identifier] isEqualToString:@"keyColumn"] && [object isEqualToString:@"Signature"]) {
		NSRunAlertPanel(@"Signature is a reserved key-value pair", @"Please choose another key name.", @"OK", nil, nil);
		return;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"keyColumn"])
		[keyArray replaceObjectAtIndex:row withObject:object];
	else
		[valueArray replaceObjectAtIndex:row withObject:object];
	
	[keyValueTable reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([keyValueTable selectedRow] == -1)
		[removeButton setEnabled:NO];
	else
		[removeButton setEnabled:YES];
}

- (IBAction)emailLicense:(id)sender;
{

	[self completeTableEntry];
	
	NSRange r;
	NSString *subjectHeaderLine;
	NSString *mailSubject = [[NSUserDefaults standardUserDefaults] objectForKey:@"MailSubject"];
	if ([mailSubject length] != 0) {
		r = [mailSubject rangeOfString:@"&P"];	// look for an &P for product name
		if (r.location == NSNotFound) { // email textField does not want to use the product name
			subjectHeaderLine = mailSubject;
		} else {
			subjectHeaderLine = [mailSubject stringByReplacingCharactersInRange:r withString:application];
		}
	} else {
		subjectHeaderLine = [NSString stringWithFormat:@"%@ License", application];
	}
	
	NSString *mailFrom = [[NSUserDefaults standardUserDefaults] objectForKey:@"MailFromAddress"];
	NSString *mailBCC = [[NSUserDefaults standardUserDefaults] objectForKey:@"MailBCCAddress"];
	NSString *mailBBCTo = @"";
	if ([mailBCC length] != 0)
		mailBBCTo = [NSString stringWithFormat: @"-b \"%@\"", mailBCC];

	NSString *licenseTextFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"LicenseTextFile"];
	NSString *licenseImageFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"LicenseImageFile"];
	NSString *licenseOtherFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"LicenseOtherFile"];

	NSString *mailTo;
	NSString *licenseName;
	NSString *tvs = [licenseEmailField stringValue];
	r = [tvs rangeOfString:@"@"];	// look for an @ in the email
	if ([tvs length] != 0) {
		if (r.location == NSNotFound) { // email textField does not have an address, look for emailAddressntainsObject:tvs];
			id key = [keyArray containsObject:tvs];
			if (key) {
				emailKey = tvs;
				licenseName = mailTo = [valueArray objectAtIndex:[keyArray indexOfObject:tvs]];
			} 
		} else {
			mailTo = tvs;
			licenseName = [valueArray objectAtIndex:0];
		}
	}
	if ([mailTo length] != 0) {
		// Do we have all the pieces
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *licenseFilePath;
		NSString *licenseFileString;
		NSString *textFileString;
		licenseFilePath = [NSString stringWithFormat: @"%@/Licenses/%@.%@", [saveDirectoryField stringValue], licenseName, [licenseExtensionField stringValue]];
		BOOL licenseFileExists = [fm isReadableFileAtPath: licenseFilePath];
		if (!licenseFileExists) {
			[self generateLicense:sender];
			licenseFileExists = [fm isReadableFileAtPath: licenseFilePath];
		}
		if (licenseFileExists) {
			licenseFileString = [NSString stringWithFormat:@"\"%@\"", licenseFilePath];

			NSString *licenseTextFilePath = [NSString stringWithFormat: @"%@/Attachments/%@", [saveDirectoryField stringValue], licenseTextFile];
			BOOL textFileExists = [fm isReadableFileAtPath: licenseTextFilePath];

			if (textFileExists) { // Have to have at least these two
				textFileString = [NSString stringWithFormat:@"\"%@\"", licenseTextFilePath];

				NSString *licenseImageFilePath = [NSString stringWithFormat: @"%@/Attachments/%@", [saveDirectoryField stringValue], licenseImageFile];
				BOOL imageFileExists = [fm isReadableFileAtPath: licenseImageFilePath];
				NSString *imageFileString;
				if (imageFileExists) 
					imageFileString = [NSString stringWithFormat:@"\"%@\"", licenseImageFilePath];
				else
					imageFileString = @"";
			
				NSString *licenseOtherFilePath = [NSString stringWithFormat: @"%@/Attachments/%@", [saveDirectoryField stringValue], licenseOtherFile];
				BOOL otherFileExists = [fm isReadableFileAtPath: licenseOtherFilePath];
				NSString *otherFileString;
				if (otherFileExists) 
					otherFileString = [NSString stringWithFormat:@"\"%@\"", licenseOtherFilePath];
				else
					otherFileString = @"";

				NSBundle *mb = [NSBundle mainBundle];
				NSString *ex = [mb executablePath];
				NSMutableArray *muttComponents = [NSMutableArray arrayWithCapacity:1];
				[muttComponents addObjectsFromArray:[ex pathComponents]];
				[muttComponents removeLastObject];
				[muttComponents addObject:@"mutt"];
				NSString *muttFilePath = [NSString pathWithComponents:muttComponents];
				NSString *mutt = [NSString stringWithFormat: @"\"%@\" -s \"%@\" %@ -a %@ %@ %@ -- %@ < %@", 
								  muttFilePath,
								  subjectHeaderLine, 
								  mailBBCTo, 
								  licenseFileString,
								  otherFileString,
								  imageFileString,
								  mailTo, 
								  textFileString
								  ];
				int result = system([mutt UTF8String]);
				if (result) {
					[MainController playUISoundForBOOL: NO];
					NSLog(@"mutt: %x", result);
				} else 
					[MainController playUISoundForBOOL: YES];
			} else {
				NSString * errorString = @"Please assign a text file for the eamil body in the preference panel";
				//				NSBeginAlertSheet(@"Could not create license file", @"OK", NULL, NULL, thisWindow, self, NULL, NULL, NULL, @"Please assign a text file for the eamil body in the preference panel");
				NSRunAlertPanel(@"Could not create license file", errorString, @"OK", nil, nil);
			}
		} else {
			NSString * errorString = @"Please assign at least one key-value pair in order to generate and email a license!";
			NSRunAlertPanel(@"Could not create license file", errorString, @"OK", nil, nil);
		}
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextView * tv = [[aNotification userInfo] objectForKey: @"NSFieldEditor"];
	NSString *tvs = [licenseEmailField stringValue];
	NSRange r = [tvs rangeOfString:@"@"];	// look for an @ in the email
	if ([tvs length] != 0) {
		if (r.location == NSNotFound) { // email texemailAddressField does not have an address, look for a key
			id key = [keyArray containsObject:tvs];
			if (key) {
				emailKey = tvs;
				emailAddress = [valueArray objectAtIndex:[keyArray indexOfObject:tvs]];
			} 
		} else {
			emailAddress = tvs;
		}
	}
	if ([emailAddress length])
		[emailButton setEnabled:YES];
	else
		[emailButton setEnabled:NO];
}
@end
