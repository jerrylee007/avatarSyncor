//
//  FriendMergeViewContriller.h
//  avatarSyncor
//
//  Created by Jerry Lee on 8/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FriendsSelectionViewControllerDelegate.h"

@interface FriendMergeViewContriller : UIViewController<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, FriendsSelectionViewControllerDelegate>

@property (nonatomic, retain) IBOutlet UITableView * friendListView;

@end
