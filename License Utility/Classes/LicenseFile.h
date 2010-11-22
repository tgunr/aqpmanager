//
//  LicenseFile.h
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 11/19/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LicenseFile : NSObject {
	NSString *fileName;
	NSMutableArray *keyInfoArray;
	NSMutableArray *valueInfoArray;
	BOOL isLicenseValid;
	NSString *licenseValidForProduct;
	NSString *hash;
}

@property (retain) 	NSString *fileName;
@property (retain) 	NSMutableArray *keyInfoArray;
@property (retain) 	NSMutableArray *valueInfoArray;
@property (assign) 	BOOL isLicenseValid;
@property (retain) 	NSString *licenseValidForProduct;
@property (retain) 	NSString *hash;

+ (LicenseFile *)initWithName: (NSString *)licenseFileName;
- (NSString *)pathToName: (NSString *)fileName;
- (BOOL)readLicenseAtPath:(NSString*)licensePath;

@end
