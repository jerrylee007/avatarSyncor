//
//  NativeFriend.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NativeFriend.h"
#import "DataManager.h"


@implementation NativeFriend

@dynamic name;
@dynamic nativeid;
@dynamic timestamp;
@dynamic sinaFriend;

+ (NativeFriend*) nativeFriendWithABRecordId: (NSInteger)abRecordId inContext:(NSManagedObjectContext*)context
{
    NSEntityDescription *nativeFriendDesc = [NSEntityDescription entityForName:@"NativeFriend" inManagedObjectContext:context];
    
    NativeFriend* nativeFriend = [[[NativeFriend alloc] initWithEntity:nativeFriendDesc insertIntoManagedObjectContext:context] autorelease];
    
    nativeFriend.nativeid = [NSString stringWithFormat:@"%d", abRecordId];
    
    nativeFriend.name = [[DataManager sharedManager].abMannager getNameOfContact:abRecordId];
    
    return nativeFriend;
}

@end
