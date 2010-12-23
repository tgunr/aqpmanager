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
#import "Mail.h"

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
    supportDir = [@"~/Library/Application Support/AquaticPrime Manager/" stringByExpandingTildeInPath];
	licenseDir = [[supportDir stringByAppendingString:@"/Generated Licenses"] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newProductCreated) name:@"NewProductCreated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productSelected) name:@"ProductSelected" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveLicenseTemplate:) name:@"ProductWillBeSelected" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productKeySelected) name:@"ProductKeySelected" object:nil];
	
	if (!infoDrawerController) {
		infoDrawerController = [InfoDrawerController new];
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
	[infoDrawerController release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)disableEverything
{
	// Disable everything
	[removeProductButton setEnabled:NO];
	[generateLicenseButton setEnabled:NO];
	[editExtensionButton setEnabled:NO];
	[editSaveDirectoryButton setEnabled:NO];
	[emailButton setEnabled:NO];
	[addKeyButton setEnabled:NO];
	[removeKeyButton setEnabled:NO];
	
	[licenseExtensionField setStringValue:@""];
	[saveDirectoryPathControl setURL: [[NSURL alloc] init]];
	[licenseEmailField setStringValue:@""];
	[[searchLicenseField cell ]setSendsWholeSearchString: YES];
	
	keyArray = [[NSMutableArray array] retain];
	valueArray = [[NSMutableArray array] retain];
	
	[licenseTable setEnabled:NO];
	[self enableLicensesTabButtons:NO];
	[infoDrawer close];
	
	[self reloadLicenses: @"*"];
}

- (void)awakeFromNib 
{
//	builtInKeywords = [NSMutableArray arrayWithCapacity:1];
	[self disableEverything];
	[addProductButton setEnabled:YES];
}

#pragma mark Variables
- (NSString *)productPath: (NSString *)product
{
	NSString * result = nil;
	if (product) {
		NSString *path = [[saveDirectoryPathControl URL] path];
		result = [NSString stringWithFormat:@"%@/%@", path, product];
	}
	return result;
}

- (NSString *)productBlackListPath: (NSString *)product
{
	NSString * result = nil;
	if (product) {
		NSString *path = [self productPath: product];
		result = [NSString stringWithFormat:@"%@/Blacklist", path];
	}
	return result;
}

- (NSString *)productAttachmentsPath: (NSString *)product
{
	NSString * result = nil;
	if (product) {
		NSString *path = [self productPath: product];
		result = [NSString stringWithFormat:@"%@/Attachments", path];
	}
	return result;
}

- (NSString *)productLicensesPath: (NSString *)product
{
	NSString * result = nil;
	if (product) {
		NSString *path = [self productPath: product];
		result = [NSString stringWithFormat:@"%@/Licenses", path];
	}
	return result;
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
//	[builtInKeywords removeAllObjects];
	
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
//					[builtInKeywords addUniqueObjectsFromArray:[lFile valueInfoArray]];
				}
			} else {
				if ([[fName pathExtension] isEqualToString:extension]) {
					lFile = [LicenseFile initWithPath: licensePathName];
					[licenseArray addObject:lFile];
//					[builtInKeywords addUniqueObjectsFromArray:[lFile valueInfoArray]];
				}
			}
		}
		NSInteger blacklistState = [blacklistRadioBtn state];
		if (blacklistState == NSOnState) {
			
			NSEnumerator *enumerator = [[productController productArray] objectEnumerator];
			id anObject;
			
			while (anObject = [enumerator nextObject]) {
				NSString * productPath = [NSString stringWithFormat:@"%@/Licenses/%@/Blacklist", [self supportDir], anObject];
				NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:productPath];
				// if the file is in the black list folder, mark it invalid
				while (fName = [dirEnum nextObject]) {
					NSString *licensePathName = [NSString stringWithFormat: @"%@/%@", licenseDir, fName];
					if ([extension isEqualToString: @"*"]) {
						if ([[fName pathExtension] hasSuffix:@"license"]) {
							lFile = [LicenseFile initWithPath: licensePathName];
							[lFile setIsLicenseValid:NO];
							[licenseArray addObject:lFile];
						}
					} else {
						if ([[fName pathExtension] isEqualToString:extension]) {
							lFile = [LicenseFile initWithPath: licensePathName];
							[lFile setIsLicenseValid:NO];
							[licenseArray addObject:lFile];
						}
					}
				}
			}			
		}

		[fm release];
	}
	[self updateNumberLicenses: [licenseArray count]];
}
		
- (void) reloadLicenseArray {
  NSString *product = [productController currentProduct];
		if (product) {
			if ([application length]) {
				NSString *productExtension = [licenseExtensionField stringValue];
				if ([productExtension length]) {
					[self reloadLicenses: productExtension];
				} else {
					[self reloadLicenses: @""];
				}				
			}
		} else
			[self reloadLicenses: @"*"];

}

- (void) searchForLicenses:(NSString *)info
{
	NSInteger narrow = [narrowResultsBtn state];
	if (narrow == NSOffState) {
		[self reloadLicenseArray];

	}
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
		[numberLicenses setStringValue: [NSString stringWithFormat:@"%d licenses found",[licenseArray count]]];
		[licenseTable reloadData];
	} else {
		[licenseArray removeAllObjects];
		[numberLicenses setStringValue: @"No licenses found"];
		[licenseTable reloadData];
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
	NSURL *pathURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/Licenses/%@.%@", [[saveDirectoryPathControl URL] absoluteString], application, [valueArray objectAtIndex:0], extension]];
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
		[searchLicenseField setStringValue:@""];
		[self reloadLicenseArray];
		[licenseTable reloadData];
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
	
	// The ~/Library/Application Support/AquaticPrime Manager/ folder doesn't exist yet
	if (![fm fileExistsAtPath:supportDir isDirectory:&isDir])
	{
		// The support path leads to a file! Bad! This shouldn't happen ever!!
		if (!isDir)
			[fm removeFileAtPath:supportDir handler:nil];
		
		// Create the ~/Library/Application Support/AquaticPrime Manager/ directory
		[fm createDirectoryAtPath:supportDir attributes:nil];
	}
	
	// The ~/Library/Application Support/AquaticPrime Manager/License Templates folder doesn't exist yet
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

#pragma mark Selections
- (void)productKeySelected
{
	NSInteger selection = [keyValueTable selectedRow];
	if (selection == -1) {
		[removeKeyButton setEnabled:NO];
	} else {
		[removeKeyButton setEnabled:YES];
	}
}

- (void)productSelected
{
	if (keyArray)
		[keyArray release];
	if (valueArray)
		[valueArray release];
		
	// Enable everything except the remove button
	[addProductButton setEnabled:YES];
	[removeProductButton setEnabled:YES];
	[generateLicenseButton setEnabled:YES];
	[editExtensionButton setEnabled:YES];
	[editSaveDirectoryButton setEnabled:YES];
	[addKeyButton setEnabled:YES];
	// No template and a product, i.e. new product
	if (![self loadLicenseTemplate] && [productController currentProduct]) {
		// Default values
		keyArray = [[NSMutableArray arrayWithObjects:@"Name", @"Email", nil] retain];
		valueArray = [[NSMutableArray arrayWithObjects:@"User", @"user@email.com", nil] retain];
		[licenseEmailField setStringValue:@"Email"];
	}
	// No product
	else if (![productController currentProduct] ) {
		[self disableEverything];
	} else {
			if ([application length]) {
				NSString *productExtension = [licenseExtensionField stringValue];
				if ([productExtension length]) {
					[self reloadLicenses: productExtension];
				} else {
					[self reloadLicenses: @""];
				}
				[licenseTable setEnabled:YES];
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
	[tabView selectTabViewItemWithIdentifier: @"2"];
	[self productSelected];
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

	NSString *basePath = [NSString stringWithFormat: @"%@/%@", saveFolder, application];
	folderExists = [fm fileExistsAtPath:basePath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@", basePath];
		result = system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}

	folderPath = [NSString stringWithFormat: @"%@/Attachments", basePath];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Attachments", basePath];
		result += system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}

	folderPath = [NSString stringWithFormat: @"%@/Licenses", basePath];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Licenses", basePath];
		result += system([mkdirString cStringUsingEncoding:NSUTF8StringEncoding]);
	}
	folderPath = [NSString stringWithFormat: @"%@/Blacklist", basePath];
	folderExists = [fm fileExistsAtPath:folderPath isDirectory: &aDir];
	if (!folderExists) {
		mkdirString = [NSString stringWithFormat:@"mkdir -p %@/Blacklist", basePath];
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

-(void)searchLicenses
{
	NSString *searchText = [searchLicenseField stringValue];
	if ([searchText length]) {
		[self searchForLicenses: searchText];
	} else
		[numberLicenses setStringValue: @"No licenses found"];	
}

- (void) enableLicensesTabButtons: (BOOL)state
{
	[mailButton setEnabled: state];
	[blackListButton setEnabled: state];
	[revealButton setEnabled: state];
}

#pragma mark TabView Delegate Methods
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	id tvi = [tabViewItem identifier];
	if ([tvi integerValue] != 3) {
		[infoDrawer close];
}
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
		case 11: {
			if ([keyArray count] <= [valueArray count])
				return [keyArray count];
			else
				return [valueArray count];
			break;
		}
		case 12: {
			if (licenseArray) {
				return [licenseArray count];
			} else {
				return 0;
			}

			break;
		}
		default:
			return 0;
			break;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSInteger tableTag = [tableView tag];
	switch (tableTag) {
		case 11: {
			if ([[tableColumn identifier] isEqualToString:@"keyColumn"])
				return [keyArray objectAtIndex:row];
			else
				return [valueArray objectAtIndex:row];
			break;
		}
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
		case 11: {
			if ([keyValueTable selectedRow] == -1)
				[removeKeyButton setEnabled:NO];
			else
				[removeKeyButton setEnabled:YES];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ProductKeySelected" object:aNotification];
			break;
		}
		case 12: {
            NSInteger selectedRow = [licenseTable selectedRow];
            if (selectedRow != -1) {
                [infoDrawerController setLicense:[licenseArray objectAtIndex:selectedRow]];
				[infoDrawer open];
				[self enableLicensesTabButtons: YES];
            } else {
				[self enableLicensesTabButtons: NO];
                [infoDrawer close];
            }
			break;
        }
		default:
			break;
	}
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSUInteger tableTag = aTableView.tag;
	switch (tableTag) {
		case 12: {
			NSString *s = aTableColumn.identifier;
			if ([s isEqualToString:@"licenseFile"]) {
				LicenseFile *lFile = [licenseArray objectAtIndex:rowIndex];
				if (![lFile isLicenseValid]) {
					[aCell setTextColor: [NSColor redColor]];
				} else
					[aCell setTextColor: [NSColor blackColor]];
			}
			break;
		}
		default:
			break;
	}
}

#pragma mark Emailing
- (NSString *) emailSubjectLine: (NSString *)product {
	NSRange r;
	NSString *subjectHeaderLine;
  NSString *mailSubject = [productController emailFieldSubject];
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

- (void)sendMessage:(NSString *)to  
			   bcc: (NSString *)bccString 
			   from: (NSString *)fromString 
			subject: (NSString *)subjectString
			body: (NSString *)bodyString
			attachments: (NSArray *)attachmentArray

{
	
	/* create a Scripting Bridge object for talking to the Mail application */
    MailApplication *mail = [SBApplication
							 applicationWithBundleIdentifier:@"com.apple.Mail"];
    
	/* create a new outgoing message object */
    MailOutgoingMessage *emailMessage =
	[[[mail classForScriptingClass:@"outgoing message"] alloc]
	 initWithProperties:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  subjectString, @"subject",
	  bodyString, @"content",
	  nil]];
	
	/* add the object to the mail app  */
    [[mail outgoingMessages] addObject: emailMessage];
    
	/* set the sender, show the message */
    emailMessage.sender = fromString;
    emailMessage.visible = YES;
	
	/* create a new recipient and add it to the recipients list */
    MailToRecipient *theRecipient =
	[[[mail classForScriptingClass:@"to recipient"] alloc]
	 initWithProperties:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  to, @"address",
	  nil]];
    [emailMessage.toRecipients addObject: theRecipient];
    
	if ([bccString length]) {
		MailToRecipient *theBCCRecipient =
		[[[mail classForScriptingClass:@"bcc recipient"] alloc]
		 initWithProperties:
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  bccString, @"address",
		  nil]];
		[emailMessage.bccRecipients addObject: theBCCRecipient];
	}
    
	
	NSEnumerator *enumerator = [attachmentArray objectEnumerator];
	id anObject;
	
	while (anObject = [enumerator nextObject]) {
		/* add an attachment, if one was specified */
		NSString *attachmentFilePath = anObject;
		if ( [attachmentFilePath length] > 0 ) {
			
			/* create an attachment object */
			MailAttachment *theAttachment = [[[mail
											   classForScriptingClass:@"attachment"] alloc]
											 initWithProperties:
											 [NSDictionary dictionaryWithObjectsAndKeys:
											  attachmentFilePath, @"fileName",
											  nil]];
			
			/* add it to the list of attachments */
			[[emailMessage.content attachments] addObject: theAttachment];
		}
	}
	
	/* send the message */
    [emailMessage send];
}
	
- (void) emailLicenseFile: (LicenseFile *) licenseFile
{
	NSString *mailBBCTo = @"";
	NSString *emailFrom;
	NSString *emailBCC;
	NSString *subjectHeaderLine;
	NSString *licenseTextFileName;
	NSString *licenseImageFileName;
	NSString *licenseOtherFileName;

	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *licenseProduct = [licenseFile licenseValidForProduct];
	if ([licenseProduct isEqualToString: [productController currentProduct]]) {
		subjectHeaderLine = [self emailSubjectLine: licenseProduct];
		
		emailBCC = [productController emailFieldBCC];
		if ([emailBCC length] != 0)
			mailBBCTo = [NSString stringWithFormat: @"-b \"%@\"", emailBCC];
		
		
		emailFrom				= [productController emailFieldFrom];
		licenseTextFileName = [productController emailLicenseTextFile];
		licenseImageFileName = [productController emailLicenseImageFile];
		licenseOtherFileName = [productController emailLicenseOtherFile];
	} else {
		[MainController playUISoundForBOOL: NO];
		NSString * errorString = @"Please assign values for emailing in the Product Data tad";
		//				NSBeginAlertSheet(@"Could not create license file", @"OK", NULL, NULL, thisWindow, self, NULL, NULL, NULL, @"Please assign a text file for the eamil body in the preference panel");
		NSRunAlertPanel(@"Could not create license file", errorString, @"OK", nil, nil);
		return;
	}


	NSString *licenseSupport = [supportDir stringByAppendingFormat:@"/Licenses/%@", licenseProduct];
	NSString *attachmentsPath = [NSString stringWithFormat: @"%@/Attachments/", licenseSupport, [licenseFile path]];

	NSMutableArray *attachmentArray = [NSMutableArray arrayWithCapacity: 1];
	
	@try {
		NSString *licenseTextFilePath = [attachmentsPath stringByAppendingString:licenseTextFileName];
		BOOL textFileExists = [fm isReadableFileAtPath: licenseTextFilePath];
		if (textFileExists) { // Have to have at least this one		
			NSMutableArray *attachmentList = [NSMutableArray array]; 
			
			if ([licenseImageFileName length]) {
				NSString *licenseImageFilePath = [attachmentsPath stringByAppendingString:licenseImageFileName];
				BOOL imageFileExists = [fm isReadableFileAtPath: licenseImageFilePath];
				if (imageFileExists) {
					NSData *imageData = [NSData dataWithContentsOfFile: licenseImageFilePath];
					[attachmentList addObject:[EDObjectPair pairWithObjects:imageData:licenseImageFileName]]; 
					[attachmentArray addObject:licenseImageFilePath];
				}
			}
			
			NSData *licenseFileData = [NSData dataWithContentsOfFile: [licenseFile fileNamePath]];
			[attachmentList addObject:[EDObjectPair pairWithObjects:licenseFileData:[licenseFile fileName]]]; 
			
			// Put the license file after any image file
			[attachmentArray addObject:[licenseFile fileNamePath]];

			if ([licenseOtherFileName length]) {
				NSString *licenseOtherFilePath = [attachmentsPath stringByAppendingString:licenseOtherFileName];
				BOOL otherFileExists = [fm isReadableFileAtPath: licenseOtherFilePath];
				if (otherFileExists) {
					NSData *otherData = [NSData dataWithContentsOfFile: licenseOtherFilePath];
					[attachmentList addObject:[EDObjectPair pairWithObjects:otherData:licenseOtherFileName]]; 
					[attachmentArray addObject:licenseOtherFilePath];
				}
			}


			NSMutableDictionary *headerFields = [NSMutableDictionary dictionary]; 
			[headerFields setObject:emailFrom forKey:@"From"]; 
			[headerFields setObject:[licenseFile HTo] forKey:@"To"]; 
			[headerFields setObject:emailBCC forKey:@"BCC"]; 
			[headerFields setObject:subjectHeaderLine forKey:@"Subject"];
			
			NSError *err;
			NSString *bodyText = [NSString stringWithContentsOfFile:licenseTextFilePath encoding:NSUTF8StringEncoding error:&err];
			
			NSInteger emailProcess = [[NSUserDefaults standardUserDefaults] integerForKey:@"MailProcess"];

			if (emailProcess == 1) {
//				NSString *encodedSubject = [NSString stringWithFormat:@"%@", [subjectHeaderLine stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//				NSString *encodedBody = [NSString stringWithFormat:@"%@", [bodyText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//				NSString *encodedTo = [[licenseFile HTo] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//				NSString *encodedBBC = [NSString stringWithFormat:@"%@", [emailBCC stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				[self sendMessage: [licenseFile HTo]  
							  bcc: emailBCC
							 from: emailFrom 
						  subject: subjectHeaderLine
							 body: bodyText
					  attachments: (NSArray *)attachmentArray];
				 
			} else {
				NSString *emailServer = [[NSUserDefaults standardUserDefaults] objectForKey:@"MailServer"];
				NSString *emailServerPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"MailServerPort"];
				
				@try {
					id mailAgent = [EDMailAgent mailAgentForRelayHostWithName:emailServer port:[emailServerPort intValue]]; 
					
					[mailAgent sendMailWithHeaders:headerFields body:bodyText andAttachments:attachmentList];
					[MainController playUISoundForBOOL: YES];
				}
				@catch (NSException * e) {
					[MainController playUISoundForBOOL: NO];
					NSString * errorString = [NSString stringWithFormat:@"An error has occured try to email the license file, please check all your settings.\n%@", [e reason]];
					//				NSBeginAlertSheet(@"Could not create license file", @"OK", NULL, NULL, thisWindow, self, NULL, NULL, NULL, @"Please assign a text file for the eamil body in the preference panel");
					NSRunAlertPanel(@"Could not mail license file", errorString, @"OK", nil, nil);
				}	
  			}

		}
	}
	@catch (NSException * e) {
		[MainController playUISoundForBOOL: NO];
		NSString * errorString = @"Please assign a text file for the eamil body in the preference panel";
		//				NSBeginAlertSheet(@"Could not create license file", @"OK", NULL, NULL, thisWindow, self, NULL, NULL, NULL, @"Please assign a text file for the eamil body in the preference panel");
		NSRunAlertPanel(@"Could not create license file", errorString, @"OK", nil, nil);
	}	
}
		
- (IBAction)emailLicenseClick:(id)sender;
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
		NSString *licenseFileString = [NSString stringWithFormat: @"%@/%@.%@", 
									   [self productLicensesPath: application], 
									   licenseName, 
									   [licenseExtensionField stringValue]];
		NSString *fixedURL = [licenseFileString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		NSURL *licenseFileURL = [NSURL URLWithString:fixedURL];
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

#pragma mark IBActions
- (IBAction)editSaveDirectory:(id)sender
{
	// Run the selection panel
	NSOpenPanel *selectPanel = [NSOpenPanel openPanel];
	[selectPanel setCanChooseFiles:NO];
	[selectPanel setCanChooseDirectories:YES];
	[selectPanel setCanCreateDirectories: YES];
	[selectPanel setAllowsMultipleSelection:NO];
	[selectPanel setPrompt:@"Select"];
	[selectPanel setTitle:@"Select Top Level Directory"];
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

- (IBAction)extensionSheetOK:(id)sender
{
	[NSApp endSheet:licenseExtensionSheet];
    [licenseExtensionSheet orderOut:self];
	NSString *extension = [[licenseExtensionEditField stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[licenseExtensionField setStringValue:extension];
}

- (IBAction)extensionSheetCancel:(id)sender
{
	[NSApp endSheet:licenseExtensionSheet];
    [licenseExtensionSheet orderOut:self];
}

- (IBAction)addKeyButtonClick:(id)sender
{
	[keyArray addObject:@"New Key"];
	[valueArray addObject:@"Undefined"];
	
	[keyValueTable reloadData];

	[generateLicenseButton setEnabled:YES];
}

- (IBAction)removeKeyButtonClick:(id)sender
{
	if ([keyValueTable selectedRow] == -1)
		return;
				else
		[keyValueTable deleteItemAtIndex:[keyValueTable selectedRow]];
}

- (IBAction)mailBtnClick:(id)sender
{
		NSInteger row = [licenseTable selectedRow];
		if (row != -1) {
			LicenseFile *license = [licenseArray objectAtIndex:row];
			[self emailLicenseFile:license];
			[license release];
		}
}

- (IBAction)revealBtnClick:(id)sender
{
	NSInteger row = [licenseTable selectedRow];
	if (row != -1) {
		LicenseFile *license = [licenseArray objectAtIndex:row];
		[license reveal];
		[license release];
	}
	
}

- (IBAction)searchBtnClick:(id)sender
{
	[self searchLicenses];
}

- (IBAction)blacklistBtnCLick:(id)sender
{
	NSInteger row = [licenseTable selectedRow];
	if (row != -1) {
		LicenseFile *license = [licenseArray objectAtIndex:row];
		[license blacklist: [self productBlackListPath: [license licenseValidForProduct]]];
		[license release];
		[self reloadLicenseArray];
		[licenseTable reloadData];
	}
}

- (IBAction)blacklistRadioClick:(id)sender
{
	[self reloadLicenseArray];
	[licenseTable reloadData];
}

- (IBAction)restoreBtnClick:(id)sender 
{
    
}

#pragma mark SearchField
// -------------------------------------------------------------------------------
//	allKeywords:
//
//	This method builds our keyword array for use in type completion (dropdown list
//	in NSSearchField).
// -------------------------------------------------------------------------------
- (NSArray *)allKeywords
{
    NSArray *array = [[[NSArray alloc] init] autorelease];
    unsigned int i,count;
			
    if (allKeywords == nil)
	{
        allKeywords = [builtInKeywords mutableCopy];

        if (array != nil)
		{
            count = [array count];
            for (i=0; i<count; i++)
			{
                if ([allKeywords indexOfObject:[array objectAtIndex:i]] == NSNotFound)
                    [allKeywords addObject:[array objectAtIndex:i]];
			}
		}
        [allKeywords sortUsingSelector:@selector(compare:)];
	}
    return allKeywords;
}

// -------------------------------------------------------------------------------
//	control:textView:completions:forPartialWordRange:indexOfSelectedItem:
//
//	Use this method to override NSFieldEditor's default matches (which is a much bigger
//	list of keywords).  By not implementing this method, you will then get back
//	NSSearchField's default feature.
// -------------------------------------------------------------------------------
//- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
// forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int*)index
//{
//    NSMutableArray*	matches = NULL;
//    NSString*		partialString;
//    NSArray*		keywords;
//    unsigned int	i,count;
//    NSString*		string;
//	
//    partialString = [[textView string] substringWithRange:charRange];
//    keywords      = [self allKeywords];
//    count         = [keywords count];
//    matches       = [NSMutableArray array];
//	
//    // find any match in our keyword array against what was typed -
//	for (i=0; i< count; i++)
//	{
//        string = [keywords objectAtIndex:i];
//        if ([string rangeOfString:partialString
//						  options:NSAnchoredSearch | NSCaseInsensitiveSearch
//							range:NSMakeRange(0, [string length])].location != NSNotFound)
//		{
//            [matches addObject:string];
//        }
//    }
//    [matches sortUsingSelector:@selector(compare:)];
//	
//	return matches;
//}

//- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
//{
//	
//}
// -------------------------------------------------------------------------------
//	controlTextDidChange:
//
//	The text in NSSearchField has changed, try to attempt type completion.
// -------------------------------------------------------------------------------
//- (void)controlTextDidChange:(NSNotification *)obj
//{
//	NSTextView* textView = [[obj userInfo] objectForKey:@"NSFieldEditor"];
//	
//    if (!completePosting && !commandHandling)	// prevent calling "complete" too often
//	{
//        completePosting = YES;
//        [textView complete:nil];
//		NSString *searchText = [searchLicenseField stringValue];
//		if ([searchText length]) {
//			[self searchForLicenses: searchText];
//		} else
//			[numberLicenses setStringValue: @"No licenses found"];		
//        completePosting = NO;
//    }
//	[licenseTable reloadData];
//}

// -------------------------------------------------------------------------------
//	control:textView:commandSelector
//
//	Handle all commend selectors that we can handle here
// -------------------------------------------------------------------------------
//- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
//{
//    BOOL result = NO;
//	
//	if ([textView respondsToSelector:commandSelector])
//	{
//        commandHandling = YES;
//        [textView performSelector:commandSelector withObject:nil];
//        commandHandling = NO;
//		
//		result = YES;
//    }
//	
//    return result;
//}

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
			
		case 3: {
            NSString* searchString = [[aNotification object] stringValue];
            if ([searchString length] == 0)
            {
                if ([application length]) {
                    NSString *productExtension = [licenseExtensionField stringValue];
                    if ([productExtension length]) {
                        [self reloadLicenses: productExtension];
                    } else {
                        [self reloadLicenses: @""];
                    }				
                }
            }
            else
            {
                [self searchLicenses];
            }
//			
//			if (!completePosting && !commandHandling)	// prevent calling "complete" too often
//			{
//				completePosting = YES;
//				[textView complete:nil];
//				[licenseTable reloadData];
//				completePosting = NO;
//			}
			break;
		}
		case 4:
			break;
			
		default:
			break;
}
	[keyValueTable reloadData];
}


#pragma TableView Actions

@end
