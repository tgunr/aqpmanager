/* MainController */

#import <Cocoa/Cocoa.h>
@class InfoController;
@class AboutController;

@interface MainController : NSObject
{
	IBOutlet NSWindow *mainWindow;
	InfoController *infoController;
	AboutController *aboutController;
}

@property (retain) 	IBOutlet NSWindow *mainWindow;

- (IBAction)showLicenseInfoWindow:(id)sender;
- (IBAction)closeWindow:(id)sender;

+ (id)shared;
+ (void)playUISound:(NSInteger)theSound;
+ (void)playUISoundForResult:(kern_return_t)theResult;
+ (void)playUISoundForBOOL:(BOOL)wasSuccess;
- (void)initPreferences;
- (IBAction) showAbout:(id) sender;
@end
