//
//  SinaFriend.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SinaFriend.h"


@implementation SinaFriend

@dynamic name;
@dynamic uid;
@dynamic screen_name;
@dynamic province;
@dynamic city;
@dynamic location;
@dynamic profile_image;
@dynamic url;
@dynamic personal_info;
@dynamic domain;
@dynamic gender;
@dynamic follower_count;
@dynamic friends_count;
@dynamic status_count;
@dynamic favourate_count;
@dynamic create_at;
@dynamic is_following;
@dynamic allow_all_act_msg;
@dynamic remark;
@dynamic geo_enabled;
@dynamic verified;
@dynamic allow_all_comment;
@dynamic avatar_large;
@dynamic verified_reason;
@dynamic follow_me;
@dynamic online_status;
@dynamic bi_followers_count;

+ (SinaFriend*) sinaFriendWithDict: (NSDictionary*)friendDict inContext:(NSManagedObjectContext*)context
{
    NSEntityDescription *sinaFriendDesc = [NSEntityDescription entityForName:@"SinaFriend" inManagedObjectContext:context];
    
    SinaFriend* sinaFriend = [[[SinaFriend alloc] initWithEntity:sinaFriendDesc insertIntoManagedObjectContext:context] autorelease];
    
    [SinaFriend updateSinaFriend:sinaFriend withDict:friendDict];
    
    return sinaFriend;
}

+ (void) updateSinaFriend:(SinaFriend*)sinaFriend withDict: (NSDictionary*)friendDict
{
    sinaFriend.uid = [[friendDict objectForKey:@"id"] stringValue];
    sinaFriend.name = [friendDict objectForKey:@"name"];
    sinaFriend.screen_name = [friendDict objectForKey:@"screen_name"];
    sinaFriend.profile_image = [friendDict objectForKey:@"profile_image_url"];
}

@end
