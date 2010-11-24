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
#import "InfoController.h"
#import "LicenseFile.h"
#import "PMMail.h"

@implementation LicenseController

@synthesize supportDir;
@synthesize licenseDir;

#pragma mark Init

static LicenseController *sharedInstance = nil;

- (id)init
{
	if (sharedInstance) {
        [self dealloc];
    } else {
        sharedInstance = [super init];
    }
	
	keyArray = [[NSMutableArray array] retain];
	valueArray = [[NSMutableArray array] retain];
	licenseArray = [[NSMutableArray array] retain];
    supportDir = [@"~/Library/Application Support/Aquatic" stringByExpandingTildeInPath];
	licenseDir = [[supportDir stringByAppendingString:@"/Generated Licenses"] retain];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newProductCreated) name:@"NewKeyGenerated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newProductSelected) name:@"ProductSelected" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveLicenseTemplate:) name:@"ProductWillBeSelected" object:nil];
	
	if (!infoController) {
		infoController = [InfoController sharedInstance];
	}	
	
	return sharedInstance;
}

+ (LicenseController *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[[self alloc] init ]autorelease];
}

- (void)dealloc
{
	[keyArray release];
	[valueArray release];
	[licenseArray release];
	[supportDir release];
	[licenseDir release];
	[infoController release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)awakeFromNib 
{
	[self createSupportDir];
	[self reloadLicenses: @"*"];
	
	NSURL *url = [[NSURL alloc] init];
	[saveDirectoryPathControl setURL:url];
}

#pragma mark License Generation

- (void) updateNumberLicenses: (NSInteger) number
{
	NSString *numberString = @"";
	if (number) {
		numberString = [NSString stringWithFormat:@"%d licenses found", number];
	} else
		numberString = [NSString stringWithFormat:@"No licenses found", number];
	[numberLicenses setStringValue:numberString];
}

- (void) reloadLicenses: (NSString *)extension {
	[licenseArray  removeAllObjects];
	
	if ([extension length]) {
		NSFileManager *fm = [NSFileManager defaultManager];		
		NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:licenseDir];
		
		NSString *fName;
		LicenseFile *lFile;
		
		while (fName = [dirEnum nextObject]) {
			NSString *licensePathName = [NSString stringWithFormat: @"%@/%@", licenseDir, fName];
			if ([extension isEqualToString: @"*"]) {
				if ([[fName pathExtension] hasSuffix:@"license"]) {
					lFile = [LicenseFile initWithPath: licensePathName];
					[licenseArray addObject:lFile];
				}
			} else {
				if ([[fName pathExtension] isEqualToString:extension]) {
					lFile = [LicenseFile initWithPath: licensePathName];
					[licenseArray addObject:lFile];
				}
			}
		}
		[fm release];
	}
	[self updateNumberLicenses: [licenseArray count]];
}
		
- (void) searchForLicenses:(NSString *)info
{
	NSMutableArray *foundLicenses = [NSMutableArray array];
	NSEnumerator *enumerator = [licenseArray objectEnumerator];

	id aLicenseFile;
	while (aLicenseFile = [enumerator nextObject]) {
		
		NSArray *vArrary = [aLicenseFile valueInfoArray];
		NSEnumerator *valueEnumerator = [vArrary objectEnumerator];
		
		id aValue;
		while (aValue = [valueEnumerator nextObject]) {
			NSRange range = [aValue rangeOfString:info options:NSCaseInsensitiveSearch];
			
			if( range.location != NSNotFound ) {
				if (![foundLicenses containsObject:aLicenseFile]) {
					[foundLicenses addObject:aLicenseFile];
				}
			}			
		}
	}
	if ([foundLicenses count]) {
		[licenseArray release];
		licenseArray = [foundLicenses retain];
		[licenseTable reloadData];
	} else {
		[NSTextField setStringValue: @"No licenses found"];
	}

}

- (void) completeTableEntry 
{
	// If a column is selected ensure it is completed
	NSInteger sr = [keyValueTable selectedRow];
	if (sr != -1) {
		[keyValueTable deselectRow:sr];
	}
}

- (void)createSupportDir {
 
	NSFileManager *fm = [NSFileManager defaultManager];
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
}

- (IBAction)generateLicense:(id)sender
{
	NSString *errorString;
	
	if ([keyArray count] == 0) {
		errorString = @"Please assign at least one key-value pair.";
		NSRunAlertPanel(@"Could not create license file", errorString, @"OK", nil, nil);
		return;
	}
	
	licenseDictionary = [NSMutableDictionary dictionaryWithObjects:valueArray forKeys:keyArray];
	
	NSString *publicKey = [keyController publicKey];
	NSString *privateKey = [keyController privateKey];
	
	if (!publicKey || !privateKey)
		return;
	
	[self completeTableEntry];

	licenseMaker = [AquaticPrime aquaticPrimeWithKey:publicKey privateKey:privateKey];

	NSString *extension = [licenseExtensionField stringValue];
	NSURL *pathURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@Licenses/%@.%@", [[saveDirectoryPathControl URL] absoluteString], [valueArray objectAtIndex:0], extension]];
	NSString *path = [pathURL path];
	NSString *backupPath = [NSString stringWithFormat:@"%@/%@.%@", licenseDir, [valueArray objectAtIndex:0], extension];
	[licenseMaker writeLicenseFileForDictionary:licenseDictionary toPath:path];
	[licenseMaker writeLicenseFileForDictionary:licenseDictionary toPath:backupPath];
	[statusController setStatus:[NSString stringWithFormat:@"Wrote license to %@", path] duration:5.0];
	
	[licenseTable reloadData];
	
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
	NSString *templateDir = [supportDir stringByAppendingString:@"/License Templates"];
	NSString *productPath = [templateDir stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", [productController productAtIndex:index]]];
	BOOL isDir;
	
	// Save this way to preserve the order of items
	NSString *saveDir = [[saveDirectoryPathControl URL] path];
	if (!saveDir) {
		saveDir = [@"~/Documents" stringByExpandingTildeInPath];
	}
	if (!emailKey) {
		emailKey = @"Email";
	}
	NSDictionary *templateDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  [productController productAtIndex:index], @"Product",
								  [licenseExtensionField stringValue], @"Extension",
								  saveDir, @"SaveDirectory", 
								  emailKey, @"EmailKey",
								  keyArray, @"Keys", 
								  valueArray, @"Values", 
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
	NSString *templateDir = [supportDir stringByAppendingString:@"/License Templates"];
	NSString *productPath = [templateDir stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", [productController currentProduct]]];

	if (![fm fileExistsAtPath:productPath])
	{
		[licenseExtensionField setStringValue:@"plist"];
		[licenseExtensionEditField setStringValue:@"plist"];
		[saveDirectoryPathControl setURL: [NSURL fileURLWithPath:[@"~/Documents" stringByExpandingTildeInPath]]];
		return NO;
	}
	
	NSDictionary *templateDict = [NSDictionary dictionaryWithContentsOfFile:productPath];
	application = [[templateDict objectForKey:@"Product"] retain];
	keyArray = [[NSMutableArray arrayWithArray:[templateDict objectForKey:@"Keys"]] retain];
	valueArray = [[NSMutableArray arrayWithArray:[templateDict objectForKey:@"Values"]] retain];
	[licenseExtensionField setStringValue:[templateDict objectForKey:@"Extension"]];
	id saveDir = [templateDict objectForKey:@"SaveDirectory"];
	if (!saveDir) {
		saveDir = [@"~/Documents" stringByExpandingTildeInPath];
	}
	NSURL *url = [NSURL fileURLWithPath: saveDir];
	[saveDirectoryPathControl setURL:url];
	
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
		licenseEmailField = [@"Email" retain];
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
			[saveDirectoryPathControl setURL: [[NSURL alloc] init]];
			[licenseEmailField setStringValue:@""];
			
			keyArray = [[NSMutableArray array] retain];
			valueArray = [[NSMutableArray array] retain];

			[self reloadLicenses: @"*"];
		} else {
			if ([application length]) {
				NSString *productExtension = [licenseExtensionField stringValue];
				if ([productExtension length]) {
					[self reloadLicenses: productExtension];
				} else {
					[self reloadLicenses: @""];
				}

			}
		}
	[keyValueTable reloadData];
	[licenseTable reloadData];
}

- (void)newProductCreated
{
	if ([productController currentProduct] )
		application = [productController currentProduct];
	else 
		application = @"";
}


#pragma mark Interface

- (IBAction)editLicenseExtension:(id)sender
{
	[licenseExtensionEditField setStringValue:[licenseExtensionField stringValue]];
	[NSApp beginSheet:licenseExtensionSheet modalForWindow:[NSApp keyWindow]
		   modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) foldersExist: (NSString *)saveFolder {
	BOOL aDir;
	BOOL folderExists;
	int result = 0; // if this is ever non zero, something went haywire
	NSString *mkdirString;
	NSString *folderPath;
	
	NSFileManager *fm = [NSFileManager defaultManager];

	folderPath = [NSString stringWithFormat: @"%@", saveFolder];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@", saveFolder];
		result = system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}

	folderPath = [NSString stringWithFormat: @"%@/Attachments", saveFolder];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Attachments", saveFolder];
		result += system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}

	folderPath = [NSString stringWithFormat: @"%@/Licenses", saveFolder];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Licenses", saveFolder];
		result += system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}
	folderPath = [NSString stringWithFormat: @"%@/Blacklist", saveFolder];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Blacklist", saveFolder];
		result += system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}
	
//	if (result == 0) 
//		NSBeginInformationalAlertSheet(@"Storage folders",
//									   @"OK",
//									   nil,
//									   nil,
//									   [sender window],               // window sheet is attached to
//									   self,                   // we'll be our own delegate
//									   nil,
//									   nil,                   // no need for did-dismiss selector
//									   nil,
//									   @"The auxiliary folders Attachments, Licenses, and Blacklist exist at \n%@",
//									   [[saveDirectoryPathControl URL] absoluteString]
//									   );                   // no parameters in message
//	else {
//		NSBeginCriticalAlertSheet(@"Storage folders",
//									   @"OK",
//									   nil,
//									   nil,
//									   [sender window],               // window sheet is attached to
//									   self,                   // we'll be our own delegate
//									   nil,
//									   nil,                   // no need for did-dismiss selector
//									   nil,
//									   @"One of auxiliary folders Attachments, Licenses, or Blacklist has NOT been created at \n%@\n Check for correct permissions or other problems that may casue a failure to create folders.",
//								  [[saveDirectoryPathControl URL] absoluteString]
//									   );                   // no parameters in message
//		[saveDirectoryPathControl setURL:[NSURL URLWithString:@""]];
//
//	}
//	return result == 0;
	[fm release];
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
	[saveDirectoryPathControl setURL:[NSURL fileURLWithPath:saveFolder isDirectory:YES]];
	
	[self foldersExist: saveFolder];
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
	NSInteger tableTag = [tableView tag];
	switch (tableTag) {
		case 11:
			if ([keyArray count] <= [valueArray count])
				return [keyArray count];
			else
				return [valueArray count];
			break;
			
		case 12:
			return [licenseArray count];
			break;
			
		case 13:
			return [blackListArray count];
			break;
			
		default:
			return 0;
			break;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSInteger tableTag = [tableView tag];
	switch (tableTag) {
		case 11:
			if ([[tableColumn identifier] isEqualToString:@"keyColumn"])
				return [keyArray objectAtIndex:row];
			else
				return [valueArray objectAtIndex:row];
			break;
			
		case 12: {
			LicenseFile *lFile = [licenseArray objectAtIndex:row];
				return [lFile fileName];
			break;
		}
			
		default:
			return 0;
			break;
	}

	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if (!object)
		return;
	NSInteger tableTag = [tableView tag];
	switch (tableTag) {
		case 11:
			if ([[tableColumn identifier] isEqualToString:@"keyColumn"] && [object isEqualToString:@"Signature"]) {
				NSRunAlertPanel(@"Signature is a reserved key-value pair", @"Please choose another key name.", @"OK", nil, nil);
				return;
			}
			
			if ([[tableColumn identifier] isEqualToString:@"keyColumn"])
				[keyArray replaceObjectAtIndex:row withObject:object];
			else {
				NSString *key = [keyArray objectAtIndex:row];
				NSRange r = [key rangeOfString:@"email" options: NSCaseInsensitiveSearch];
				if (r.location == NSNotFound) { // key for this row does not contain "Email"
					NSString *columnValue = [object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					columnValue = [columnValue stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
					columnValue = [columnValue stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
					[valueArray replaceObjectAtIndex:row withObject:columnValue];
				} else {
					PMMail *email = [PMMail initWithEmailAddress: object];
					NSString *mailtoString = [email emailAddress];
					[valueArray replaceObjectAtIndex:row withObject:mailtoString];
				}
			}
			[keyValueTable reloadData];
			break;
			
		case 12:
			break;
			
		default:
			break;
	}
	
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSTableView *nTV = [aNotification object];
	NSInteger tableTag = [nTV tag];
	switch (tableTag) {
		case 11:
            if ([keyValueTable selectedRow] == -1)
                [removeButton setEnabled:NO];
            else
                [removeButton setEnabled:YES];
			break;
			
		case 12: {
            NSInteger selectedRow = [licenseTable selectedRow];
            if (selectedRow != -1) {
                [[InfoController sharedInstance] setLicense:[licenseArray objectAtIndex:selectedRow]];
                [infoDrawer open];
            } else {
                [infoDrawer close];
            }
			break;
        }
		default:
			break;
	}
}

- (NSString *) emailSubjectLine: (NSString *)product {
  NSRange r;
  NSString *subjectHeaderLine;
  NSString *mailSubject = [[NSUserDefaults standardUserDefaults] objectForKey:@"MailSubject"];
	if ([mailSubject length] != 0) {
		r = [mailSubject rangeOfString:@"&P"];	// look for an &P for product name
		if (r.location == NSNotFound) { // email textField does not want to use the product name
			subjectHeaderLine = mailSubject;
		} else {
			subjectHeaderLine = [mailSubject stringByReplacingCharactersInRange:r withString:product];
		}
	} else {
		subjectHeaderLine = [NSString stringWithFormat:@"%@ License", product];
	}
  return subjectHeaderLine;
}

- (void) emailLicenseFile: (LicenseFile *) licenseFile
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *licenseProduct = [licenseFile licenseValidForProduct];
	NSString *subjectHeaderLine = [self emailSubjectLine: licenseProduct];
	
	//	NSString *mailFrom = [[NSUserDefaults standardUserDefaults] objectForKey:@"MailFromAddress"];
	NSString *mailBCC = [[NSUserDefaults standardUserDefaults] objectForKey:@"MailBCCAddress"];
	NSString *mailBBCTo = @"";
	if ([mailBCC length] != 0)
		mailBBCTo = [NSString stringWithFormat: @"-b \"%@\"", mailBCC];
	
	NSString *licenseTextFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"LicenseTextFile"];
	NSString *licenseImageFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"LicenseImageFile"];
	NSString *licenseOtherFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"LicenseOtherFile"];
	NSString *licenseFilePath = [licenseFile path];
	NSString *licenseFileString = [NSString stringWithFormat:@"\"%@/%@\"", licenseFilePath, [licenseFile fileName]];
	NSString *licenseSupport = [supportDir stringByAppendingFormat:@"/Licenses/%@", licenseProduct];
	NSString *attachmentsPath = [NSString stringWithFormat: @"%@/Attachments/", licenseSupport, licenseFilePath];

	NSString *textFileString;
	NSString *licenseTextFilePath = [attachmentsPath stringByAppendingString:licenseTextFile];
	BOOL textFileExists = [fm isReadableFileAtPath: licenseTextFilePath];
	if (textFileExists) { // Have to have at least this one
		textFileString = [NSString stringWithFormat:@"\"%@\"", licenseTextFilePath];
		
		NSString *imageFileString = @"";
		if (licenseImageFile) {
			NSString *licenseImageFilePath = [attachmentsPath stringByAppendingString:licenseImageFile];
			BOOL imageFileExists = [fm isReadableFileAtPath: licenseImageFilePath];
			if (imageFileExists) 
				imageFileString = [NSString stringWithFormat:@"\"%@\"", licenseImageFilePath];
		}
		
		NSString *otherFileString = @"";
		if (licenseOtherFile) {
			NSString *licenseOtherFilePath = [attachmentsPath stringByAppendingString:licenseOtherFile];
			BOOL otherFileExists = [fm isReadableFileAtPath: licenseOtherFilePath];
			NSString *otherFileString;
			if (otherFileExists) 
				otherFileString = [NSString stringWithFormat:@"\"%@\"", licenseOtherFilePath];
		}
		
		NSBundle *mb = [NSBundle mainBundle];
		NSString *ex = [mb executablePath];
		NSMutableArray *muttComponents = [NSMutableArray arrayWithCapacity:1];
		[muttComponents addObjectsFromArray:[ex pathComponents]];
		[muttComponents removeLastObject];
		[muttComponents addObject:@"mutt"];
		NSString *muttFilePath = [NSString pathWithComponents:muttComponents];
		muttFilePath = @"/opt/local/bin/mutt";
		NSString *mutt = [NSString stringWithFormat: @"\"%@\" -s \"%@\" %@ -a %@ %@ %@ -- %@ < %@", 
						  muttFilePath,
						  subjectHeaderLine, 
						  mailBBCTo, 
						  licenseFileString,
						  otherFileString,
						  imageFileString,
						  [licenseFile HTo], 
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
	
}
- (IBAction)emailLicense:(id)sender;
{

	[self completeTableEntry];
	
	NSRange r;
	NSString *mailTo;
	NSString *licenseName;
	NSString *tvs = [licenseEmailField stringValue];
	r = [tvs rangeOfString:@"@"];	// look for an @ in the email
	if ([tvs length] != 0) {
		if (r.location == NSNotFound) { // email textField does not have an address, look for emailAddressntainsObject:tvs];
			BOOL keyResult = [keyArray containsObject:tvs];
			if (keyResult) {
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
		NSString *licenseFileString;
		NSURL *licenseFileURL = [NSURL URLWithString:[NSString stringWithFormat: @"%@Licenses/%@.%@", [[saveDirectoryPathControl URL] absoluteString], licenseName, [licenseExtensionField stringValue]]];
		NSString *licenseFilePath = [licenseFileURL path];
		BOOL licenseFileExists = [fm isReadableFileAtPath: licenseFilePath];
		if (!licenseFileExists) {
			[self generateLicense:sender];
			licenseFileExists = [fm isReadableFileAtPath: licenseFilePath];
		}
		if (licenseFileExists) {
			licenseFileString = [NSString stringWithFormat:@"\"%@\"", licenseFilePath];

			LicenseFile *licenseFile = [LicenseFile initWithPath:licenseFilePath];
			[licenseFile setHTo:mailTo];
			[self emailLicenseFile: licenseFile];
			[licenseFile release];
		} else {
			NSString * errorString = @"Please assign at least one key-value pair in order to generate and email a license!";
			NSRunAlertPanel(@"Could not create license file", errorString, @"OK", nil, nil);
		}
	}
}

- (IBAction)sendLicenseFile:(id)sender
{
		NSInteger row = [licenseTable selectedRow];
		if (row) {
			LicenseFile *license = [licenseArray objectAtIndex:row];
			[self emailLicenseFile:license];
			[license release];
		}
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTabViewItem *tab = [tabView selectedTabViewItem];
	NSInteger tableTag = [[tab identifier] integerValue];
	switch (tableTag) {
		case 1: {
            id n = [aNotification object];
			NSInteger tagID = [n tag];
			id tv = [[aNotification userInfo] objectForKey: @"NSFieldEditor"];
			NSInteger selectedRow = [keyValueTable selectedRow];
			NSInteger selectedCol = [keyValueTable selectedColumn];
			NSInteger keyCol = [keyValueTable columnWithIdentifier:@"keyColumn"];
			NSString * c = [n stringValue];
			switch (tagID) {
				case 1: {
					NSString *tvs = [licenseEmailField stringValue];
					NSRange r = [tvs rangeOfString:@"@"];	// look for an @ in the email
					if ([tvs length] != 0) {
						if (r.location == NSNotFound) { // email texemailAddressField does not have an address, look for a key
							BOOL keyResult = [keyArray containsObject:tvs];
							if (keyResult) {
								emailKey = tvs;
								emailAddress = [valueArray objectAtIndex:[keyArray indexOfObject:tvs]];
							} 
						} else {
							emailAddress = tvs;
						}
						PMMail *email = [PMMail initWithEmailAddress: emailAddress];
						emailAddress = [email emailAddress];
						break;
					}
				}
				case 11: {
					if (selectedRow != -1) {
						
						NSString *value = [valueArray objectAtIndex:selectedRow];
						NSString *key = [keyArray objectAtIndex:selectedRow];
						NSString *columnValue = [[tv string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						columnValue = [columnValue stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
						columnValue = [columnValue stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
						
						// Special check for the key named "Email"
						if (selectedCol != keyCol) {
							NSRange r = [key rangeOfString:@"email" options: NSCaseInsensitiveSearch];
							
							if (r.location == NSNotFound) { // key for this row does not contain "Email"
								[valueArray replaceObjectAtIndex:selectedRow withObject:columnValue];
							} else {
								BOOL ok = [PMMail isEmail: columnValue];
								PMMail *email = [PMMail initWithEmailAddress: columnValue];
								NSString *mailtoString = [email emailAddress];
								emailAddress = mailtoString;
								[valueArray replaceObjectAtIndex:selectedRow withObject:mailtoString];
							}
						} else
							[valueArray replaceObjectAtIndex:selectedRow withObject:columnValue];
					}
					break;
				}
			
				default:
					break;
			}
			if ([emailAddress length])
				[emailButton setEnabled:YES];
			else
				[emailButton setEnabled:NO];
			break;
		}
			
		case 2: {
			NSString *searchText = [searchLicenseField stringValue];
			[self searchForLicenses: searchText];
			break;
		}
		case 3:
			break;
			
		default:
			break;
	}
	[keyValueTable reloadData];
}

- (IBAction)searchForLicense:(id)sender
{
    
}

- (IBAction)blackListLicense:(id)sender
{
    
}

- (IBAction)searchForBlackList:(id)sender
{
    
}

- (IBAction)restoreLicense:(id)sender 
{
    
}

#pragma TableView Actions

@end
