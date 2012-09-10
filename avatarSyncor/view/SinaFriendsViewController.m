//
//  SecondViewController.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SinaFriendsViewController.h"
#import "ViewConstants.h"
#import "SinaSDKManager.h"
#import "ControllerConstants.h"
#import "ViewHelper.h"
#import "iToast.h"
#import "FriendViewCell.h"
#import "UIImageView+WebCache.h"
#import "SinaFriend.h"
#import "DataManager.h"
#import "CoreDataManager.h"
#import "FriendMergeViewContriller.h"

#define K_NOTIFICATION_RETRIEVE_FRIENDS_PROGRESS  @"K_NOTIFICATION_RETRIEVE_FRIENDS_PROGRESS"
#define K_NOTIFICATION_RETRIEVE_FRIENDS_DONE  @"K_NOTIFICATION_RETRIEVE_FRIENDS_DONE"

#define UIPROGRESSVIEW_WIDTH    (240.0)
#define UIPROGRESSVIEW_HEIGHT    (50.0)

#define MAX_FRIENDS_COUNT_PER_REQUEST   (20)

@interface SinaFriendsViewController ()
@property(nonatomic, assign)  processDoneWithDictBlock getFriendDoneCallback;

@property(nonatomic, assign)  CGFloat friendsTotalCount;
@property(nonatomic, assign)  CGFloat friendsRetrievedCount;
@property(nonatomic, retain)  NSString * next_cousor;

@property(nonatomic, retain)  NSMutableArray * sinaFriends;

@property (retain, nonatomic) id observerForRetrieveProgress;
@property (retain, nonatomic) id observerForRetrieveDone;


- (void)onFriendsRetrievesDone;

@end

@implementation SinaFriendsViewController

@synthesize getFriendDoneCallback = _getFriendDoneCallback;
@synthesize observerForRetrieveDone = _observerForRetrieveDone;
@synthesize friendsRetrievedCount = _friendsRetrievedCount;
@synthesize friendsTotalCount = _friendsTotalCount;
@synthesize next_cousor = _next_cousor;

@synthesize sinaFriends = _sinaFriends;

@synthesize observerForRetrieveProgress = _observerForRetrieveProgress;

@synthesize sinaFriendsTableView = _sinaFriendsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}
							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)dealloc
{
    [_next_cousor release];
    [_sinaFriends removeAllObjects];
    [_sinaFriends release];
    
    [super release];
}


- (void)onFriendsRetrievesDone
{
    [[NSNotificationCenter defaultCenter] postNotificationName:K_NOTIFICATION_RETRIEVE_FRIENDS_DONE object:self userInfo:nil];
    
    for (NSDictionary * sinaFriendDict in self.sinaFriends) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid == %@",
                                  [[sinaFriendDict objectForKey:@"id"] stringValue]];
        SinaFriend * sinaFriend = (SinaFriend*)[[CoreDataManager sharedManager] fetchEntity:@"SinaFriend" withPredicate:predicate prefetchRelations:nil context:[CoreDataManager sharedManager].managedObjectContext];
        
        if (sinaFriend == nil) {
            [SinaFriend sinaFriendWithDict:sinaFriendDict inContext:[CoreDataManager sharedManager].managedObjectContext];
        }
        else
        {
            [SinaFriend updateSinaFriend:sinaFriend withDict:sinaFriendDict];
        }
    }
    
    [[CoreDataManager sharedManager] saveMainContextChanges];
    
    // Start Merge view
    FriendMergeViewContriller * friendMergeViewController = [[[FriendMergeViewContriller alloc] initWithNibName:nil bundle:nil] autorelease];
    
    UINavigationController * navController= [[UINavigationController alloc] initWithRootViewController: friendMergeViewController];
    [self presentModalViewController: navController animated:YES];
    [navController release];
}

- (void)retrieveAllFriends
{
    __block NSInteger friendsCountPerRequest = 0;
    friendsCountPerRequest = MIN(MAX_FRIENDS_COUNT_PER_REQUEST, _friendsTotalCount);
    
    __block processDoneWithDictBlock getFriendsDoneBlock = ^(AIO_STATUS status, NSDictionary *data)
    {
        if (status == AIO_STATUS_SUCCESS) {
            _next_cousor = [[data objectForKey:@"next_cursor"] stringValue];
            
            [self.sinaFriends addObjectsFromArray:[data objectForKey:@"users"]];
            
            if ([_next_cousor isEqualToString:@"0"]) {
                [self onFriendsRetrievesDone];
            }
            else
            {
                _friendsRetrievedCount += friendsCountPerRequest;
                [[NSNotificationCenter defaultCenter] postNotificationName:K_NOTIFICATION_RETRIEVE_FRIENDS_PROGRESS object:self userInfo:nil];
                [self retrieveAllFriends];  
            }
        }
        else
        {
            [[iToast makeText:@"好友接收失败，请重试!"] show];
        }

    };
    
    [[SinaSDKManager sharedManager] getFriendsOfUser:[ViewHelper getUserUid] cursor:_next_cousor count:friendsCountPerRequest doneCallback:getFriendsDoneBlock];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    [self.sinaFriendsTableView setDelegate:self];
    [self.sinaFriendsTableView setDataSource:self];
    
    
    [self.sinaFriendsTableView setHidden:YES];
    
    __block UIProgressView * loadingProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [loadingProgressView setFrame:CGRectMake((SCREEN_WIDTH - UIPROGRESSVIEW_WIDTH)/2, 100.0, UIPROGRESSVIEW_WIDTH, UIPROGRESSVIEW_HEIGHT)];
    
    [self.view addSubview:loadingProgressView];
    
    [[SinaSDKManager sharedManager] getInfoOfUser:[ViewHelper getUserUid] doneCallback:^(AIO_STATUS status, NSDictionary *data) {
        if (status == AIO_STATUS_SUCCESS) {
            self.friendsTotalCount = [[data objectForKey:@"friends_count"] intValue];
            _next_cousor = @"0";
            self.sinaFriends = [NSMutableArray arrayWithCapacity:self.friendsTotalCount];
            [self retrieveAllFriends];
        }
        else
        {
            [[iToast makeText:@"获取信息失败，请再试一次!"] show];
        }
    }];
    
    self.observerForRetrieveProgress = [[NSNotificationCenter defaultCenter]
                                        addObserverForName:K_NOTIFICATION_RETRIEVE_FRIENDS_PROGRESS
                                        object:nil
                                        queue:nil
                                        usingBlock:^(NSNotification *note) {
                                            [loadingProgressView setProgress:_friendsRetrievedCount/_friendsTotalCount];
                                        }];
    self.observerForRetrieveDone = [[NSNotificationCenter defaultCenter]
                                    addObserverForName:K_NOTIFICATION_RETRIEVE_FRIENDS_DONE
                                    object:nil
                                    queue:nil
                                    usingBlock:^(NSNotification *note) {
                                        [loadingProgressView removeFromSuperview];
                                                                                    [self.sinaFriendsTableView setHidden:NO];
                                                                                    [self.sinaFriendsTableView reloadData];
                                    }];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:_observerForRetrieveProgress];
    self.observerForRetrieveProgress = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:_observerForRetrieveDone];
    self.observerForRetrieveDone = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
    static NSString * friendViewCellIdentifier = @"FriendViewCell";
    
    FriendViewCell *cell = [tableView dequeueReusableCellWithIdentifier:friendViewCellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:friendViewCellIdentifier owner:self options:nil] objectAtIndex:0];
    }
    
    cell.name.text = [[self.sinaFriends objectAtIndex:[indexPath row]] objectForKey:@"screen_name"];
    
    NSString * imageUrl =[[self.sinaFriends objectAtIndex:[indexPath row]] objectForKey:@"profile_image_url"]; 

    [cell.avatar setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"avatar_icon"]];
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.sinaFriends count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //    self.currentCommentIndex = [indexPath row];
    //    self.relatedCommentId = [[self.forwardOrCommentList objectAtIndex:self.currentCommentIndex] valueForKey:K_BSDK_UID];
    //    self.relatedCommentUserName = [[[self.forwardOrCommentList objectAtIndex:self.currentCommentIndex] valueForKey:K_BSDK_USERINFO] objectForKey:K_BSDK_USERNAME];
    //    [self startCommentListAction];
}

@end
