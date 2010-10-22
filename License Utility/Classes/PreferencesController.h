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
}

- (IBAction)runPreferences:(id)sender;
- (IBAction)clickTool:(NSToolbarItem*)sender;
- (IBAction)refreshUpdateDate:(id)sender;
- (IBAction)provideFeedback:(id)sender;
@end
