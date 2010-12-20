//
//  PreferencesController.h
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 10/16/10.
//  Copyright (c) 2010 Polymicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreferencesController : NSObject {
@private
	IBOutlet NSPanel *prefsWindow;
	IBOutlet NSTabView *tabView;
	IBOutlet NSToolbar *tabToolBar;

	IBOutlet NSTextField *updateText;
	IBOutlet NSForm *mailServer;
	IBOutlet NSFormCell *hostName;
	IBOutlet NSFormCell *hostPort;
	IBOutlet NSTableView *accountsTable;
	
    IBOutlet NSButtonCell *appleMailButton;
    IBOutlet NSButtonCell *internalMailButton;

	NSMutableArray *emailAccounts;
}
@property (retain) 	NSArray *emailAccounts;

- (IBAction)runPreferences:(id)sender;
- (IBAction)clickTool:(NSToolbarItem*)sender;
- (IBAction)refreshUpdateDate:(id)sender;
- (IBAction)provideFeedback:(id)sender;
@end
