//
//  PreferencesController.m
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 10/16/10.
//  Copyright (c) 2010 Polymicro Systems. All rights reserved.
//

#import "PreferencesController.h"


@implementation PreferencesController

static PreferencesController *shared;

- (id)init {
    if (shared) 
	{
        [self autorelease];
        return shared;
    }
    if ((self = [super init])) {
        // Initialization code here.
		shared = self;
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
	[prefsWindow release];
	[tabView release];
	[tabToolBar release];
	[updateText release];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.SULastCheckTime"];
    [super dealloc];
}

- (void)awakeFromNib {
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.SULastCheckTime" options:0 context:NULL];
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController] && ([keyPath hasSuffix:@"SULastCheckTime"]))
		[self refreshUpdateDate:self];
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	
	NSArray* theItems = [toolbar items];
	NSInteger theCount = [theItems count];
	NSInteger index;
	NSMutableArray* theArray = [NSMutableArray arrayWithCapacity:theCount];
	
	for(index=0; index<theCount; index++)
		[theArray addObject:[[theItems objectAtIndex:index] itemIdentifier]];
	
	NSLog(@"Selectables: %@", theArray);
	
	return theArray;
}

- (NSToolbarItem*)toolbarItemForIdentifier:(NSString*)id
{
	NSToolbarItem*		outToolbarItem = nil;
	NSArray*			toolbarItems = [tabToolBar visibleItems];
	int					index, count = [toolbarItems count];
	
	for( index=0; index < count; index++ )
	{
		outToolbarItem = [toolbarItems objectAtIndex:index];
		if( [[outToolbarItem itemIdentifier] compare:id] == NSOrderedSame )
			break;
		if( [[outToolbarItem label] compare:id] == NSOrderedSame )
			break;
		outToolbarItem = nil;
	}
	
	return outToolbarItem;
}

- (IBAction)runPreferences:(id)sender
{
	NSString*	startToolID = [[NSUserDefaults standardUserDefaults] objectForKey:@"PrefToolSelected"];
	
	if( tabToolBar ) 
		[self clickTool:[self toolbarItemForIdentifier:startToolID]];
	[self refreshUpdateDate:self];
	if( prefsWindow ) 
		[prefsWindow makeKeyAndOrderFront:sender];
}

- (IBAction)clickTool:(NSToolbarItem*)sender
{
	NSLog(@"Clicked Tool Label:%@ ID:%@", [sender label], [sender itemIdentifier]);
	if( tabView ) 
		[tabView selectTabViewItemWithIdentifier: [sender label]];
	if( tabToolBar ) 
		[tabToolBar setSelectedItemIdentifier: [sender itemIdentifier]];
	
	[[NSUserDefaults standardUserDefaults] setObject:[sender itemIdentifier] forKey:@"PrefToolSelected"];
		
	[self refreshUpdateDate:sender];
	
	NSView*		theTabView = [[tabView selectedTabViewItem] view]; 
	NSRect		theBottomFrame = [[theTabView viewWithTag:99] frame]; // Special item
	NSRect		theTabFrame = [theTabView frame];
	NSRect		theWindowFrame = [[tabView window] frame];
	NSRect		theContentFrame = [[tabView window] contentRectForFrameRect:theWindowFrame];
	NSPoint		theNewSize; // = theTabFrame.size;
	
	float		theToolbarHeight = -(theWindowFrame.size.height - theContentFrame.size.height);
	float		theNewHeight = (theWindowFrame.size.height - (theTabFrame.size.height - theBottomFrame.origin.y)) + theToolbarHeight;
	float		theDeltaHeight = theWindowFrame.size.height - theNewHeight;
	float		theDeltaOrigin = theWindowFrame.origin.y + theNewHeight;
	
	theNewSize.x = theBottomFrame.size.width;
	theNewSize.y = theTabFrame.size.height - theBottomFrame.origin.y;
	
	theWindowFrame.size.width = theBottomFrame.size.width;
	theWindowFrame.size.height = theDeltaHeight; // theTabFrame.size.height - theBottomFrame.origin.y;
	theWindowFrame.origin.y = theDeltaOrigin;
	
	//[[tabView window] setContentSize:theWindowFrame.size];
	[[tabView window] setFrame:theWindowFrame display:YES animate:YES];
}


- (IBAction)refreshUpdateDate:(id)sender
{
	NSDate*		theDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"SULastCheckTime"];
	NSString*	theLastCheckFormat = NSLocalizedString(@"Last Check: %@", @"Prefs Window Update Tab Last Check Prompt Format for last update check date");
	NSString*	theUpdateString = NSLocalizedString(@"Never checked for an update.", @"Prefs Window Update Tab Last Check Prompt default when no update check date is found");
	
	CFLocaleRef			thisLocale = CFLocaleCopyCurrent();
	CFDateFormatterRef	thisFormat = CFDateFormatterCreate( kCFAllocatorDefault, thisLocale, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle );
	CFStringRef			thisDate = NULL;
	
	if( theDate ) {
		thisDate = CFDateFormatterCreateStringWithDate( kCFAllocatorDefault, thisFormat, (CFDateRef)theDate );
		theUpdateString = [NSString stringWithFormat:theLastCheckFormat, (NSString*)thisDate];
		CFRelease( thisDate );
	}
	
	if( updateText ) [updateText setStringValue:theUpdateString];
	
	CFRelease( thisFormat );
	CFRelease( thisLocale );	
}

- (IBAction)provideFeedback:(id)sender
{
	CFURLRef	feedbackURL = CFURLCreateWithString( kCFAllocatorDefault, CFCopyLocalizedString(CFSTR("http://polymicro.net/products/aqprime/feedback/"), CFSTR("URL used when user selects Provide User Feedback")), NULL );
	CFURLRef	launchURL;
	
	LSOpenCFURLRef( feedbackURL, &launchURL );
}

@end
