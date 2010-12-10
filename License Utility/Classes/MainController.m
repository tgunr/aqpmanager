#import "MainController.h"
#import "InfoController.h"
#import "AboutController.h"
#import <AudioToolbox/AudioToolbox.h>

#define PREFS_VERSION	(const char*)"0.1"

@implementation MainController
@synthesize mainWindow;

static MainController *shared;

+ (id)shared
{
    if (!shared) {
        [[MainController alloc] init];
    }
    return shared;
}

- (id)init
{
    if (shared) 
	{
        [self autorelease];
        return shared;
    }
    if (self = [super init])
	{	
		//	Initializtion 
		shared = self;
		
		[self initPreferences];
		
	}
    return self; 
}

- (void)awakeFromNib
{
	[mainWindow makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([[[aNotification object] frameAutosaveName] isEqualToString:@"mainWindow"])
		[NSApp terminate:self];
}

- (IBAction)showAboutBox:(id)sender
{
	if (!aboutController) {
		aboutController = [[AboutController alloc] init];
	}
	
	[[aboutController window] makeKeyAndOrderFront:self];
}

- (IBAction)showLicenseInfoWindow:(id)sender
{
	if (!infoController) {
		infoController = [[InfoController alloc] init];
	}
	[infoController showWindow:self];
}

- (IBAction)closeWindow:(id)sender
{
	[[NSApp keyWindow] orderOut:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
	if ([[aMenuItem title] isEqualToString:@"Close"]) {
		if (![NSApp keyWindow])
			return NO;
	}
	return YES;
}

+ (void)playUISound:(NSInteger)theSound
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"PlaySounds"] == YES ) 
		AudioServicesPlaySystemSound( (SystemSoundID)theSound );
}

+ (void)playUISoundForResult:(kern_return_t)theResult
{
	SystemSoundID	theSound = kASSystemSoundDoink;
	
	if( theResult == kIOReturnSuccess ) 
		theSound = kASSystemSoundSuccess;
	
	[self playUISound:theSound];
	
}

+ (void)playUISoundForBOOL:(BOOL)wasSuccess
{
	SystemSoundID	theSound = kASSystemSoundDoink;
	
	if( wasSuccess == YES ) 
		theSound = kASSystemSoundSuccess;
	
	[self playUISound:theSound];
	
}

- (void)initPreferences
{
	NSMutableDictionary*	defaultPrefs = [NSMutableDictionary dictionaryWithCapacity:0];
	NSNumber*				boolTRUE = [NSNumber numberWithInt:1];
//	NSNumber*				boolFALSE = [NSNumber numberWithInt:0];
	NSString*				prefsVersion = [NSString stringWithCString:PREFS_VERSION encoding:NSUTF8StringEncoding];
	NSString*				currentVersion = nil;
	BOOL					needsUpdate = NO;
	BOOL					gotUpdate = NO;
	NSUserDefaults*			defaults = [NSUserDefaults standardUserDefaults];
	
	currentVersion = [defaults stringForKey:@"PrefsVersion"];
	
	if( !currentVersion || ![prefsVersion isEqual:currentVersion] )
		needsUpdate = YES;
	
	[defaultPrefs setObject:prefsVersion forKey:@"PrefsVersion"];
	[defaultPrefs setObject:boolTRUE forKey:@"PlaySounds"];
	[defaultPrefs setObject:boolTRUE forKey:@"SUAutoUpdate"];
	[defaultPrefs setObject:boolTRUE forKey:@"SUSendInfo"];
	
	[defaultPrefs setObject:@"915FC355-A57B-43AB-A8CE-CC039D82A446" forKey:@"PrefToolSelected"];
	
	[defaults registerDefaults:defaultPrefs];
	
	if( needsUpdate )
	{
		//if( currentVersion == nil ) 
		//	gotUpdate = YES;
		
		if( [currentVersion compare:@"0.1"] == NSOrderedSame )
			gotUpdate = YES;
		
		//	User upgrading to prefs should get a new toolbar in case they've saved one
		//if( [prefsVersion compare:@"0.0"] == NSOrderedSame )
		//	[defaults removeObjectForKey:@"NSToolbar Configuration CBD4AF57-273A-43B1-B47C-55D929D9CF3D"];
		
		//gotUpdate = YES;
		
		if( gotUpdate == YES ) {
			[defaults setObject:prefsVersion forKey:@"PrefsVersion"];
			[defaults synchronize];
			if( currentVersion == nil ) 
				currentVersion = [NSString stringWithCString:(const char*)"0.1" encoding:NSUTF8StringEncoding];
			NSLog(@"Updated preferences from version %@ to version %@", currentVersion, prefsVersion);
		}
	}
	
}

- (IBAction) showAbout:(id) sender {
	[[NSApplication sharedApplication] orderFrontStandardAboutPanel: self];
}


@end
