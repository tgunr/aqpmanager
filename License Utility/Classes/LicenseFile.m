//
//  LicenseFile.m
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 11/19/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "LicenseFile.h"
#import "KeyController.h"
#import "AquaticPrime.h"
#import "LicenseController.h"

@implementation LicenseFile
@synthesize fileNamePath;
@synthesize keyInfoArray;
@synthesize valueInfoArray;
@synthesize isLicenseValid;
@synthesize licenseValidForProduct;
@synthesize hash;
@synthesize HTo;

- (id) init
{
	self = [super init];
	if (self != nil) {
		keyInfoArray = [[NSMutableArray alloc] init];
		valueInfoArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSString *)pathToName: (NSString *)fName 
{
	return [[[LicenseController sharedInstance] licenseDir] stringByAppendingString: [NSString stringWithFormat:@"/%@", fName]];
}

+ (LicenseFile *)initWithPath: (NSString *)licenseFilePath
{
	LicenseFile *licenseFile = [[[LicenseFile alloc] init] retain];
	[licenseFile readLicenseAtPath: licenseFilePath];

	return licenseFile;
}

- (NSString *)fileName
{
	return [fileNamePath lastPathComponent];
	
}

- (NSString *)path
{
	NSMutableArray * components = [NSMutableArray arrayWithArray:[fileNamePath pathComponents]	];
	NSString *first = [components objectAtIndex:0];
	if ([first isEqual:@"/"]) {
		[components removeObjectAtIndex:0];
	}
	[components removeLastObject];
	NSString *path = [@"/" stringByAppendingString: [components componentsJoinedByString:@"/"]];
	return [path retain];
}

- (BOOL)readLicenseAtPath:(NSString*)licenseNamePath
{	
	BOOL result = NO;
	fileNamePath = licenseNamePath;
    NSDictionary *licenseDictionary = [NSDictionary dictionaryWithContentsOfFile:fileNamePath];
	
	// If it doesn't have a signature, don't accept the drop
	if (![licenseDictionary objectForKey:@"Signature"])
		return result;
	
	// Grab all the product keys that we have
	NSDictionary *productKeyDictionary = [[KeyController sharedInstance] allPublicKeys];
	NSArray *productArray = [productKeyDictionary allKeys];
	
	// Determine if the license is valid for any of the products
	int productIndex;
	for (productIndex = 0; productIndex < [productArray count]; productIndex++)
	{
		NSString *currentProduct = [productArray objectAtIndex:productIndex];
		NSData *publicKey = [productKeyDictionary objectForKey:currentProduct];
		NSMutableString *publicKeyString = [NSMutableString stringWithString:[publicKey description]];
		[publicKeyString replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [publicKeyString length])];
		[publicKeyString replaceOccurrencesOfString:@"<" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [publicKeyString length])];
		[publicKeyString replaceOccurrencesOfString:@">" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [publicKeyString length])];
		
		AquaticPrime *licenseChecker = [AquaticPrime aquaticPrimeWithKey:[NSString stringWithFormat:@"0x%@", publicKeyString]];
        [licenseDictionary release];
		licenseDictionary = [licenseChecker dictionaryForLicenseFile:fileNamePath];
		
		if (licenseDictionary) {
			keyInfoArray = [[licenseDictionary allKeys] retain];
			valueInfoArray = [[licenseDictionary allValues] retain];
			hash = (NSString *)[licenseChecker hash];
			isLicenseValid = YES;
			licenseValidForProduct = [currentProduct retain];
			NSUInteger emailKey = [keyInfoArray indexOfObject:@"Email"];
			if (emailKey) {
				HTo = [valueInfoArray objectAtIndex:emailKey];
			}
			result = YES;
		}
	}
	
	// At this point, the license is invalid, but we show the key-value pairs anyway
	NSMutableDictionary *badLicenseDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:fileNamePath];
	[badLicenseDictionary removeObjectForKey:@"Signature"];
	keyInfoArray = [[NSMutableArray arrayWithArray:[badLicenseDictionary allKeys]] retain];
	valueInfoArray = [[NSMutableArray arrayWithArray:[badLicenseDictionary allValues]] retain];
	
	return result;
}

@end
