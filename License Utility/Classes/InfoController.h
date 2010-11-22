/* InfoController */

#import <Cocoa/Cocoa.h>
@class LicenseFile;

@interface InfoController : NSWindowController
{
	IBOutlet NSView *licenseInfoView;
	IBOutlet NSWindow *licenseWindow;
	IBOutlet NSTableView *keyValueInfoTable;
	IBOutlet NSTextField *licenseValidField;
	IBOutlet NSTextField *hashField;
	
	LicenseFile *licenseFile;
	
}

+ (InfoController *)sharedInstance;
- (void)setLicense:(LicenseFile *)license;
@end