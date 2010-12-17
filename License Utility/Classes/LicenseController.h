//
// LicenseController.h
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

#import <Cocoa/Cocoa.h>
@class AQTableView;
@class AquaticPrime;
@class InfoController;
@class LicenseFile;

@interface LicenseController : NSObject
{
	IBOutlet NSTabView *tabView;
	IBOutlet NSDrawer *infoDrawer;
	
	// Generate Licenses Tab
    IBOutlet AQTableView *keyValueTable;
	IBOutlet NSButton *addProductButton;
	IBOutlet NSButton *removeProductButton;
	IBOutlet NSButton *generateLicenseButton;
	IBOutlet NSButton *editExtensionButton;
	IBOutlet NSButton *editSaveDirectoryButton;
	IBOutlet NSTextField *licenseExtensionField;
	IBOutlet NSPathControl *saveDirectoryPathControl;
	IBOutlet NSTextField *licenseExtensionEditField;
	IBOutlet NSPanel *licenseExtensionSheet;
	IBOutlet NSTextField *licenseEmailField;
	IBOutlet NSButton *emailButton;
	
    // Licenses Tab
	BOOL					completePosting;
    BOOL					commandHandling;
    BOOL					searching;
	NSMutableArray			*allKeywords;
	NSMutableArray			*builtInKeywords;

    IBOutlet NSSearchField *searchLicenseField;
    IBOutlet NSButton *searchLicenseBtn;
    IBOutlet NSButton *narrowResultsBtn;
    IBOutlet NSButton *blacklistRadioBtn;
    IBOutlet NSTableView *licenseTable;
    IBOutlet NSButton *mailButton;
    IBOutlet NSButton *blackListButton;
	IBOutlet NSTextField *numberLicenses;
	IBOutlet NSButton *revealButton;
	IBOutlet NSButton *addKeyButton;
    IBOutlet NSButton *removeKeyButton;

	NSMutableArray *keyArray;
	NSMutableArray *valueArray;
	NSMutableArray *licenseArray;
	NSMutableArray *blackListArray;
	
	NSString *emailKey;
	NSString *emailAddress;
	NSString *application;
	NSMutableDictionary *licenseDictionary;
	AquaticPrime *licenseMaker;
	
	NSString *supportDir;
	NSString *licenseDir;
	NSString *saveDirectory;
	
	IBOutlet id keyController;
	IBOutlet id statusController;
	IBOutlet id productController;
	IBOutlet id infoController;
	IBOutlet NSArrayController *licenseArrayController;

}

@property (retain) 	NSString *supportDir;
@property (retain) 	NSString *licenseDir;

+ (LicenseController *)sharedInstance;

- (IBAction)generateLicense:(id)sender;
- (void)saveLicenseTemplate:(id)table;
- (BOOL)loadLicenseTemplate;
- (void)newProductSelected;
- (IBAction)editLicenseExtension:(id)sender;
- (IBAction)editSaveDirectory:(id)sender;
- (IBAction)emailLicenseClick:(id)sender;
- (IBAction)mailBtnClick:(id)sender;
- (IBAction)revealBtnClick:(id)sender;
- (IBAction)searchBtnClick:(id)sender;
- (IBAction)blacklistBtnCLick:(id)sender;
- (IBAction)blacklistRadioClick:(id)sender;

- (IBAction)addKeyButtonClick:(id)sender;
- (IBAction)removeKeyButtonClick:(id)sender;

- (IBAction)extensionSheetOK:(id)sender;
- (IBAction)extensionSheetCancel:(id)sender;

- (void)reloadLicenses: (NSString *)extension;
- (void)reloadLicenseArray;
- (void) enableLicensesTabButtons: (BOOL)state;

- (NSString *)productPath: (NSString *)product;
- (NSString *)productBlackListPath: (NSString *)product;
- (NSString *)productAttachmentsPath: (NSString *)product;
- (NSString *)productLicensesPath: (NSString *)product;
  
@end

