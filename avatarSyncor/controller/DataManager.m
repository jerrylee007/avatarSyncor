/***********************************************************************
 *
 * Copyright (C) 2011-2012 Myriad Group AG. All Rights Reserved.
 *
 * File     :   $Id: //depot/ds/projects/MSSS/pivot/apps/Pivot/Pivot/Controller/DataManager.m#198 $
 *
 ***********************************************************************/

#import "DataManager.h"
#import "ViewConstants.h"

static DataManager *sharedInstance;


@implementation DataManager

@synthesize abMannager = _abMannager;

#pragma mark - Class methods

+ (DataManager*) sharedManager {
    @synchronized([DataManager class]) {
        if (!sharedInstance) {
            sharedInstance = [[DataManager alloc] init];
        }
    }
    return sharedInstance;
}

#pragma mark - init/dealloc
- (void)dealloc {
    
    [super dealloc];
}

- (id)init {
    self = [super init];
    
    
    _abMannager = [[AddressBookManager alloc] init];
    if (self) {
        // run at next iteration to avoid call datamanager init recursively.
        dispatch_async(dispatch_get_main_queue(), ^{
        });
        
    }
    
    return self;
}
- (void)handleLowMemory {
}


@end

/** @} */
