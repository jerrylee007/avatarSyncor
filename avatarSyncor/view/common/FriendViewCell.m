//
//  FriendViewCell.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FriendViewCell.h"

@implementation FriendViewCell

@synthesize avatar = _avatar;
@synthesize name = _name;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)dealloc {
    [_avatar release];
    [_name release];
    [super dealloc];
}

@end
