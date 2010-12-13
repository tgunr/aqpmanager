//
//  LicenseArrayController.m
//  AquaticPrime Developer
//
//  Created by Dave Carlton on 11/29/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "LicenseArrayController.h"


@implementation LicenseArrayController

- (void)search:(id)sender
{
    [self setSearchString:[sender stringValue]];
    [self rearrangeObjects];    
}


// Set default values, and keep reference to new object -- see arrangeObjects:
- (id)newObject
{
    newObject = [super newObject];
    [newObject setValue:@"First" forKey:@"firstName"];
    [newObject setValue:@"Last" forKey:@"lastName"];
    return newObject;
}



- (NSArray *)arrangeObjects:(NSArray *)objects
{
	
    if ((searchString == nil) ||
		([searchString isEqualToString:@""]))
	{
		newObject = nil;
		return [super arrangeObjects:objects];   
	}
	
	/*
	 Create array of objects that match search string.
	 Also add any newly-created object unconditionally:
	 (a) You'll get an error if a newly-added object isn't added to arrangedObjects.
	 (b) The user will see newly-added objects even if they don't match the search term.
	 */
    
    NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    // case-insensitive search
    NSString *lowerSearch = [searchString lowercaseString];
    
	NSEnumerator *oEnum = [objects objectEnumerator];
    id item;	
    while (item = [oEnum nextObject])
	{
		// if the item has just been created, add it unconditionally
		if (item == newObject)
		{
            [matchedObjects addObject:item];
			newObject = nil;
		}
		else
		{
			//  Use of local autorelease pool here is probably overkill, but may be useful in a larger-scale application.
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSString *lowerName = [[item valueForKeyPath:@"firstName"] lowercaseString];
			if ([lowerName rangeOfString:lowerSearch].location != NSNotFound)
			{
				[matchedObjects addObject:item];
			}
			else
			{
				lowerName = [[item valueForKeyPath:@"lastName"] lowercaseString];
				if ([lowerName rangeOfString:lowerSearch].location != NSNotFound)
				{
					[matchedObjects addObject:item];
				}
			}
			[pool release];
		}
    }
    return [super arrangeObjects:matchedObjects];
}


//  - dealloc:
- (void)dealloc
{
    [self setSearchString: nil];    
    [super dealloc];
}


// - searchString:
- (NSString *)searchString
{
	return searchString;
}
// - setSearchString:
- (void)setSearchString:(NSString *)newSearchString
{
    if (searchString != newSearchString)
	{
        [searchString autorelease];
        searchString = [newSearchString copy];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	
}
@end
