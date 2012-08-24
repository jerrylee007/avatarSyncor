//
//  FriendViewCell.h
//  avatarSyncor
//
//  Created by Jerry Lee on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MergeViewCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UIImageView * localAvatarImageView;
@property (nonatomic, retain) IBOutlet UILabel * localName;

@property (nonatomic, retain) IBOutlet UIImageView * sinaAvatarImageView;
@property (nonatomic, retain) IBOutlet UILabel * sinaName;

@end
