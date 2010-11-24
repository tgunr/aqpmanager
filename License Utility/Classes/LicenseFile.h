//
//  LicenseFile.h
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 11/19/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LicenseFile : NSObject {
	NSString *fileNamePath;
	NSMutableArray *keyInfoArray;
	NSMutableArray *valueInfoArray;
	BOOL isLicenseValid;
	NSString *licenseValidForProduct;
	NSString *hash;
	NSString *HFrom;
	NSString *HTo;
	NSString *HSubject;
	NSString *HBody;
}

@property (retain) 	NSString *fileNamePath;
@property (retain) 	NSMutableArray *keyInfoArray;
@property (retain) 	NSMutableArray *valueInfoArray;
@property (assign) 	BOOL isLicenseValid;
@property (retain) 	NSString *licenseValidForProduct;
@property (retain) 	NSString *hash;
@property (retain) 	NSString *HTo;

+ (LicenseFile *)initWithPath: (NSString *)licenseFilePath;
- (NSString *)pathToName: (NSString *)fileNamePath;
- (BOOL)readLicenseAtPath:(NSString*)licensePath;
- (NSString *)fileName;
- (NSString *)path;
@end
