//
//  SinaFriend.h
//  avatarSyncor
//
//  Created by Jerry Lee on 8/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SinaFriend : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSString * province;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * profile_image;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * personal_info;
@property (nonatomic, retain) NSString * domain;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSNumber * follower_count;
@property (nonatomic, retain) NSNumber * friends_count;
@property (nonatomic, retain) NSNumber * status_count;
@property (nonatomic, retain) NSNumber * favourate_count;
@property (nonatomic, retain) NSDate * create_at;
@property (nonatomic, retain) NSNumber * is_following;
@property (nonatomic, retain) NSNumber * allow_all_act_msg;
@property (nonatomic, retain) NSString * remark;
@property (nonatomic, retain) NSNumber * geo_enabled;
@property (nonatomic, retain) NSNumber * verified;
@property (nonatomic, retain) NSNumber * allow_all_comment;
@property (nonatomic, retain) NSString * avatar_large;
@property (nonatomic, retain) NSString * verified_reason;
@property (nonatomic, retain) NSNumber * follow_me;
@property (nonatomic, retain) NSNumber * online_status;
@property (nonatomic, retain) NSNumber * bi_followers_count;


+ (SinaFriend*) sinaFriendWithDict: (NSDictionary*)friendDict inContext:(NSManagedObjectContext*)context;

+ (void) updateSinaFriend:(SinaFriend*)sinaFriend withDict: (NSDictionary*)friendDict;
@end
