/* InfoController.h */

#import <Cocoa/Cocoa.h>
@class LicenseFile;

@interface InfoDrawerController : NSWindowController
{
	IBOutlet NSView *licenseInfoView;
	IBOutlet NSWindow *licenseWindow;
	IBOutlet NSTableView *keyValueInfoTable;
	IBOutlet NSTextField *licenseValidField;
	IBOutlet NSTextField *hashField;
	
	LicenseFile *licenseFile;
}

+ (InfoDrawerController *)sharedInstance;
- (void)setLicense:(LicenseFile *)license;
@end

@interface InfoWindowController : InfoDrawerController
{
}

@end