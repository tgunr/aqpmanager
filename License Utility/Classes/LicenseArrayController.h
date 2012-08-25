//
//  LicenseArrayController.h
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 11/29/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LicenseArrayController : NSArrayController
{    NSString *searchString;
    id newObject;
}

- (void)search:(id)sender;
- (NSString *)searchString;
- (void)setSearchString:(NSString *)newSearchString;

@end
