//
//  NativeFriend.h
//  avatarSyncor
//
//  Created by Jerry Lee on 8/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SinaFriend.h"


@interface NativeFriend : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * nativeid;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) SinaFriend * sinaFriend;

+ (NativeFriend*) nativeFriendWithABRecordId: (NSInteger)abRecordId inContext:(NSManagedObjectContext*)context;

@end
