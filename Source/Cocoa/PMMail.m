//
//  PMMail.m
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 11/23/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "PMMail.h"

@implementation PMMail
@synthesize emailAddress;
@synthesize recipient;


+(PMMail *) initWithEmailAddress: (NSString *) email
{
	id newInstance = [[self alloc] init]; 
	NSRange r = [email rangeOfString:@"@"];
	if (r.location == NSNotFound)
		[newInstance setEmailAddress: nil];
	else
		[newInstance setEmailAddress: email];
	[newInstance clean];
	return newInstance;
}

-(void)clean
{
	if (emailAddress) {
		NSString *mailtoString = @"mailto:";
		NSString *stringValue = [emailAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[emailAddress release];
		stringValue = [stringValue stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
		stringValue = [stringValue stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
		stringValue = [stringValue stringByReplacingOccurrencesOfString:mailtoString withString:@""];
		NSRange r = [emailAddress rangeOfString:@"<" options: NSCaseInsensitiveSearch];
		if (r.location != NSNotFound) {
			// Extract the name
			NSRange nameRange = NSMakeRange(0,14);
			NSString * possibleName = [emailAddress substringWithRange:nameRange];
			[self setRecipient: possibleName];
			// Delete the name
			NSString *emailSet = @"\"<>";
			NSArray *eArray = [emailAddress componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: emailSet]];
			NSString *realEmail = [eArray stringFromArray];
		}
			emailAddress = [stringValue retain];
	}
}

+(BOOL) isEmail: (NSString *)inputEmail
{
	inputEmail  = [NSString string];
	NSString *emailRegEx =
	@"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
	@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
	@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
	@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
	@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
	@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
	@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";

	NSString * strRegex = [[NSArray arrayWithObjects: @"^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}",
						  @"\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\"",
						  @".)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$",
						   nil] stringFromArray];
						  
	NSPredicate *regExPredicate1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
	NSPredicate *regExPredicate2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", strRegex];
	BOOL myStringMatchesRegEx1 = [regExPredicate1 evaluateWithObject:inputEmail];	
	return NO;
}

@end