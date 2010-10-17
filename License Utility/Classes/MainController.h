/* MainController */

#import <Cocoa/Cocoa.h>
@class InfoController;
@class AboutController;

@interface MainController : NSObject
{
	NSWindow *mainWindow;
	InfoController *infoController;
	AboutController *aboutController;
}

- (IBAction)showLicenseInfoWindow:(id)sender;
- (IBAction)closeWindow:(id)sender;

+ (id)shared;
+ (void)playUISound:(NSInteger)theSound;
+ (void)playUISoundForResult:(kern_return_t)theResult;
+ (void)playUISoundForBOOL:(BOOL)wasSuccess;
- (void)initPreferences;
@end
