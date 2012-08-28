//
//  FriendMergeViewContriller.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FriendMergeViewContriller.h"
#import "DataManager.h"
#import "CoreDataManager.h"
#import "NativeFriend.h"
#import "SinaFriend.h"
#import "MergeViewCell.h"
#import "SinaFriendsViewController.h"
#import "ViewHelper.h"
#import "FriendsSelectionViewController.h"
#import "UIImageView+WebCache.h"

#define ACTIONSHEET_MERGE_ACTION            (1)

#define MERGE_ACTION_START                  @"选择新浪好友进行头像同步"
#define MERGE_ACTION_RESET                  @"删除现有的头像同步"

@interface FriendMergeViewContriller ()

@property (nonatomic, retain) NSArray * localFriends;
@property (nonatomic, assign) NSInteger currentFriendIndex;
- (void)startMergeAction;

@end

@implementation FriendMergeViewContriller

@synthesize friendListView = _friendListView;
@synthesize localFriends = _localFriends;
@synthesize currentFriendIndex = _currentFriendIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self.navigationItem setLeftBarButtonItem:[ViewHelper getBackBarItemOfTarget:self action:@selector(onBackButtonClicked) title:NSLocalizedString(@"返回", @"返回")]];
        [self.navigationItem setTitle:@"同步"];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)dealloc
{
    [_localFriends release];
    [_friendListView release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.friendListView setDelegate:self];
    [self.friendListView setDataSource:self];
    
    self.localFriends = [[CoreDataManager sharedManager] fetchAllEntities:@"NativeFriend" 
                                             withPredicate:nil 
                                               withSorting:nil
                                                fetchLimit:0
                                         prefetchRelations:nil 
                                                    context:[CoreDataManager sharedManager].managedObjectContext];


}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.localFriends = nil;
    self.friendListView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) onBackButtonClicked
{
    if (![self.navigationController popViewControllerAnimated:YES])
    {
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark Table view delegate and data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * mergeViewCellIdentifier = @"MergeViewCell";
    
    MergeViewCell *cell = [tableView dequeueReusableCellWithIdentifier:mergeViewCellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:mergeViewCellIdentifier owner:self options:nil] objectAtIndex:0];
    }
    
    NativeFriend * nativeFriend = (NativeFriend*)[_localFriends objectAtIndex:[indexPath row]];
    cell.localName.text = nativeFriend.name;
    
    cell.localAvatarImageView.image = [[DataManager sharedManager].abMannager getAvatarOfContact:[nativeFriend.nativeid intValue]];
    
    if (cell.localAvatarImageView.image == nil) {
        cell.localAvatarImageView.image = [UIImage imageNamed:@"avatar_icon"];
    }
    
    if (nativeFriend.sinaFriend) {
        cell.sinaName.text = nativeFriend.sinaFriend.name;
        [cell.sinaAvatarImageView setImageWithURL:[NSURL URLWithString:nativeFriend.sinaFriend.profile_image]];
    }
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.localFriends count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        self.currentFriendIndex = [indexPath row];
    //    self.relatedCommentId = [[self.forwardOrCommentList objectAtIndex:self.currentCommentIndex] valueForKey:K_BSDK_UID];
    //    self.relatedCommentUserName = [[[self.forwardOrCommentList objectAtIndex:self.currentCommentIndex] valueForKey:K_BSDK_USERINFO] objectForKey:K_BSDK_USERNAME];
    //    [self startCommentListAction];
    
    
    [self startMergeAction];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [actionSheet destructiveButtonIndex])
    {
        switch (actionSheet.tag)
        {
            case ACTIONSHEET_MERGE_ACTION:
            {
                NSString *pressed = [actionSheet buttonTitleAtIndex:buttonIndex];
                
                if ([pressed isEqualToString:MERGE_ACTION_START])
                {
                    FriendsSelectionViewController * sinaFriendsSelectViewController = [[[FriendsSelectionViewController alloc] initWithNibName:nil bundle:nil] autorelease];
                    
                    UINavigationController * navController= [[UINavigationController alloc] initWithRootViewController: sinaFriendsSelectViewController];
                    
                    [sinaFriendsSelectViewController setDelegate:self];
                    
                    [self presentModalViewController: navController animated:YES];
                    [navController release];

                }
                else if ([pressed isEqualToString:MERGE_ACTION_RESET])
                {
                    FriendsSelectionViewController * sinaFriendsSelectViewController = [[[FriendsSelectionViewController alloc] initWithNibName:nil bundle:nil] autorelease];
                    
                    UINavigationController * navController= [[UINavigationController alloc] initWithRootViewController: sinaFriendsSelectViewController];
                    
                    [sinaFriendsSelectViewController setDelegate:self];
                    
                    [self presentModalViewController: navController animated:YES];
                    [navController release];
                }

            }
            default:
                break;
        }
    }
}

- (void)startMergeAction
{
    UIActionSheet * mergeActionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                                         delegate:self
                                                                cancelButtonTitle:nil
                                                           destructiveButtonTitle:nil
                                                                otherButtonTitles:nil];
    
    mergeActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    mergeActionSheet.tag = ACTIONSHEET_MERGE_ACTION;
    

    [mergeActionSheet addButtonWithTitle:MERGE_ACTION_START];        

    [mergeActionSheet addButtonWithTitle:MERGE_ACTION_RESET];

    [mergeActionSheet setDestructiveButtonIndex:[mergeActionSheet addButtonWithTitle:NSLocalizedString(@"取消", @"取消")]];
    [mergeActionSheet showInView:self.view];
    
    [mergeActionSheet release];
}

- (void)didFinishContactSelectionWithContacts:(SinaFriend *)friend
{
    NativeFriend * nativeFriend =  [self.localFriends objectAtIndex:self.currentFriendIndex];
    
    nativeFriend.sinaFriend = friend;
    
    [[DataManager sharedManager].abMannager updateABRecord:[nativeFriend.nativeid intValue] withAvatarUrl:friend.profile_image];
    
    [self.friendListView reloadData];
    
    [[CoreDataManager sharedManager] saveMainContextChanges];
}

- (void)didCancelContactSelection
{

}

@end
