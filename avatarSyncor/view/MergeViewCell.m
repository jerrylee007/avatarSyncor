//
//  FriendViewCell.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MergeViewCell.h"

@implementation MergeViewCell

@synthesize localAvatarImageView = _localAvatarImageView;
@synthesize localName = _localName;

@synthesize sinaAvatarImageView = _sinaAvatarImageView;
@synthesize sinaName = _sinaName;

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
    [_localAvatarImageView release];
    [_localName release];
    
    [_sinaAvatarImageView release];
    [_sinaName release];
    
    [super dealloc];
}

@end
