//
// InfoController.m
// AquaticPrime Developer
//
// Copyright (c) 2005, Lucas Newman
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//	Ôæ•Redistributions of source code must retain the above copyright notice,
//	 this list of conditions and the following disclaimer.
//	Ôæ•Redistributions in binary form must reproduce the above copyright notice,
//	 this list of conditions and the following disclaimer in the documentation and/or
//	 other materials provided with the distribution.
//	Ôæ•Neither the name of Aquatic nor the names of its contributors may be used to 
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

#import "InfoController.h"
#import "KeyController.h"
#import "AquaticPrime.h"
#import "LicenseFile.h"

@implementation InfoDrawerController

static InfoDrawerController *sharedInfoDrawer = nil;

- (id)init
{
	self = [super init];
    if (self) {
		if (!sharedInfoDrawer) {
			sharedInfoDrawer = self;
		}
    }
    return self;
}

+ (InfoDrawerController *)sharedInstance
{
	if (sharedInfoDrawer == nil) {
		[[self alloc] init];
	}
    return sharedInfoDrawer;
}

- (void)awakeFromNib
{
	licenseFile = [LicenseFile new];
}

- (IBAction)closeLicenseInfoWindow:(id)sender
{
	[[self window] orderOut:self];
}

- (void)setLicense:(LicenseFile *)license
{
    if (licenseFile)
        [licenseFile release];
    licenseFile = [license retain];
	[[self window] setTitle:[license fileName]];
	NSString *valid = [licenseFile isLicenseValid] ? [NSString stringWithFormat:@"This license is valid for %@", [licenseFile licenseValidForProduct]] 
    : @"This license is invalid";
	[licenseValidField setStringValue:valid];
	if (![licenseFile isLicenseValid]) {
		[licenseValidField setTextColor: [NSColor redColor]];
	} else {
		NSColor *aColor = [NSColor colorWithCalibratedRed:0.165 green:0.502 blue:0.216 alpha:1.000];
		[licenseValidField setTextColor: aColor];
	}
	
	[hashField setStringValue:[NSString stringWithFormat:@"License Hash: %@", [licenseFile hash]]]; 
    [keyValueInfoTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[licenseFile keyInfoArray] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqualToString:@"keyInfoColumn"])
		return [[licenseFile keyInfoArray] objectAtIndex:row];
	else
		return [[licenseFile valueInfoArray] objectAtIndex:row];
}

@end

@implementation InfoWindowController

- (id)init
{
	self = [super init];
    if (self) {
		self = [super initWithWindowNibName:@"LicenseInfo"];
    }
    return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	[[self window] registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
	return NSDragOperationLink;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSArray *filenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	if ([filenames count] != 1)
		return NO;
	
	NSString *licensePath = [filenames objectAtIndex:0];
	if (![licenseFile readLicenseAtPath:licensePath])
		return NO;
	
	[[self window] setTitle:[licensePath lastPathComponent]];
	NSString *valid = [licenseFile isLicenseValid] ? [NSString stringWithFormat:@"This license is valid for %@", [licenseFile licenseValidForProduct]] 
	: @"This license is invalid";
	[licenseValidField setStringValue:valid];
	[hashField setStringValue:[NSString stringWithFormat:@"License Hash: %@", [licenseFile hash]]]; 
	[[self window] setContentView:licenseInfoView];
	
	return YES;
}

@end