//
//  LicenseFile.h
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 11/19/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LicenseFile : NSObject {
	NSString *name;
	NSMutableArray *keyInfoArray;
	NSMutableArray *valueInfoArray;
	BOOL isLicenseValid;
	NSString *licenseValidForProduct;
	NSString *hash;
}

@property (retain) 	NSString *name;
@property (retain) 	NSMutableArray *keyInfoArray;
@property (retain) 	NSMutableArray *valueInfoArray;
@property (assign) 	BOOL isLicenseValid;
@property (retain) 	NSString *licenseValidForProduct;
@property (retain) 	NSString *hash;

- (NSString *)pathToName: (NSString *)fileName;
- (BOOL)readLicenseAtPath:(NSString*)licensePath;

@end
