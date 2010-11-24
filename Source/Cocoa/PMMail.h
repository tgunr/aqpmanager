//
//  PMMail.h
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 11/23/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PMMail : NSObject {
	NSString *emailAddress;
	NSString *recipient;
}
@property NSString *emailAddress;
@property NSString *recipient;

+(PMMail *)initWithEmailAddress: (NSString *)email;
+(BOOL) isEmail: (NSString *)inputEmail;
-(void)clean;
@end
