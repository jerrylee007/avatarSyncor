//
//  FirstViewController.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LocalFriendsViewController.h"
#import "AddressBookManager.h"
#import "DataManager.h"
#import "FriendViewCell.h"
#import "NativeFriend.h"
#import "CoreDataManager.h"
#import "AddressBookManager.h"

@interface LocalFriendsViewController ()

@property (nonatomic, retain) NSArray * localFriends;
@end

@implementation LocalFriendsViewController

@synthesize friendsTableView = _friendsTableView;
@synthesize localFriends = _localFriends;

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
-(void)dealloc
{
    [_friendsTableView release];
    [_localFriends release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
   
    if (_localFriends == nil) {
        self.localFriends = [[DataManager sharedManager].abMannager getAllABRecordIds];
    }
    
//    NSArray *list = [[CoreDataManager sharedManager] fetchAllEntities:@"NativeFriend" 
//                                             withPredicate:[NSPredicate predicateWithFormat: @"name beginswith 'Ke'"] 
//                                               withSorting:nil
//                                                fetchLimit:0
//                                         prefetchRelations:nil 
//                                                   context:[CoreDataManager sharedManager].managedObjectContext];
    
    

    
    for (NSNumber* recordId in self.localFriends) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nativeid == %@",
                                  recordId];
        NativeFriend * nativeFriend = (NativeFriend*)[[CoreDataManager sharedManager] fetchEntity:@"NativeFriend" withPredicate:predicate prefetchRelations:nil context:[CoreDataManager sharedManager].managedObjectContext];
        
        if (nativeFriend == nil) {
            [NativeFriend nativeFriendWithABRecordId:[recordId intValue] inContext:[CoreDataManager sharedManager].managedObjectContext];
        }
        else
        {
            if ([[[DataManager sharedManager].abMannager getUpdateDateForContact:[recordId intValue]] compare:nativeFriend.timestamp])
            {
                //TODO: record it
            }
        }
    }
    
    [[CoreDataManager sharedManager] saveMainContextChanges];
    
    [self.friendsTableView setDelegate:self];
    [self.friendsTableView setDataSource:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.localFriends = nil;
    self.friendsTableView = nil;
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

#pragma mark Table view delegate and data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * friendViewCellIdentifier = @"FriendViewCell";
    
    FriendViewCell *cell = [tableView dequeueReusableCellWithIdentifier:friendViewCellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:friendViewCellIdentifier owner:self options:nil] objectAtIndex:0];
    }
    
    cell.name.text = [[DataManager sharedManager].abMannager getNameOfContact:[[_localFriends objectAtIndex:[indexPath row]] intValue]];
    
    cell.avatar.image = [[DataManager sharedManager].abMannager getAvatarOfContact:[[_localFriends objectAtIndex:[indexPath row]] intValue]];
    
    if (cell.avatar.image == nil) {
        cell.avatar.image = [UIImage imageNamed:@"avatar_icon"];
    }
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [_localFriends count];
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
