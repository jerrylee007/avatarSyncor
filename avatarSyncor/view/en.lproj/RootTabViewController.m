//
//  RootTabViewController.m
//  BeautifulDaRen
//
//  Created by jerry.li on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RootTabViewController.h"
#import "ViewConstants.h"
#import "CustomUITabBarItem.h"
#import "LocalFriendsViewController.h"
#import "SinaFriendsViewController.h"
#import "UIImage+Scale.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "SinaSDKManager.h"

@interface RootTabViewController()

- (void)initLocalizedString;

@end

@implementation UINavigationBar (UINavigationBarCategory)
- (void)drawRect:(CGRect)rect {
    UIImage *image = [UIImage imageNamed: @"nav_bar_background"];
    [image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}
@end

@implementation RootTabViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

-(void)dealloc
{
//    [[NSNotificationCenter defaultCenter] removeObserver:_observerForLogout];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    [self initLocalizedString];

    if (!SYSTEM_VERSION_LESS_THAN(@"5.0"))
    {
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"nav_bar_background"] forBarMetrics:UIBarMetricsDefault];

        [[UIToolbar appearance]setBackgroundImage:[UIImage imageNamed:@"toolbar_background"] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
    }
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{

}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    NSAssert([viewController isKindOfClass:[UINavigationController class]],@"viewController should be UINavigationController");
    UINavigationController * navController = (UINavigationController*)viewController;
//    [navController popToRootViewControllerAnimated:NO];
//    // when clicked HomeView, it should be turn to home view.
//    if (![[BSDKManager sharedManager] isLogin] && !([navController.topViewController isKindOfClass:[HomeViewController class]] || [navController.topViewController isKindOfClass:[CategoryViewController class]])) {
//        
////        [[NSNotificationCenter defaultCenter] postNotificationName:K_NOTIFICATION_SHOULD_LOGIN object:self];
//
//        LoginViewController * loginContorller = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
//        UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController: loginContorller];
//        [self presentModalViewController:navController animated:YES];
//        [navController release];
//        [loginContorller release];
//
//        return NO;
//    }
//    else if ( [navController.topViewController isKindOfClass:[MyShowViewController class]] )
//    {
//        [self startMyshowAction];
//        return NO;
//    }
    if ([navController.topViewController isKindOfClass:[SinaFriendsViewController class]] && ![[SinaSDKManager sharedManager] isLogin])
    {
        LoginViewController * loginViewController = [[[LoginViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        
        UINavigationController * navController= [[UINavigationController alloc] initWithRootViewController: loginViewController];
        [self presentModalViewController: navController animated:YES];
        [navController release];
        return NO;
    }
    
    return YES;
}

- (void)initLocalizedString
{
    NSArray* nativeArray = [NSArray arrayWithObjects:NSLocalizedString(@"tab_native1", @"tab_native1"),NSLocalizedString(@"tab_native1", @"tab_native1"),nil];
    NSArray* sinaArray = [NSArray arrayWithObjects:NSLocalizedString(@"tab_sina", @"tab_sina"),NSLocalizedString(@"tab_sina", @"tab_sina"),nil];
    NSArray* settingArray = [NSArray arrayWithObjects:NSLocalizedString(@"tab_setting", @"tab_setting"),NSLocalizedString(@"tab_setting", @"tab_setting"),nil];
    
    NSArray* localizedStringsArray = [NSArray arrayWithObjects:nativeArray, sinaArray, settingArray, nil];
    
    NSArray* tabbarIconNamesArray = [NSArray arrayWithObjects:@"tabbar_home_icon", @"tabbar_hot_icon", @"tabbar_show_icon", @"tabbar_search_icon", @"tabbar_mine_icon", nil];
    
    NSInteger index = 0;
    for (UINavigationController* navigation in [self customizableViewControllers]){
        UINavigationItem* navigationItem = navigation.topViewController.navigationItem;
        NSArray* textArray = [localizedStringsArray objectAtIndex:index];
        [navigationItem setTitle:[textArray objectAtIndex:0]];
        
        CustomUITabBarItem * tempTabBarItem = [[CustomUITabBarItem alloc] initWithTitle:[textArray objectAtIndex:1] normalImage:[UIImage imageNamed:[tabbarIconNamesArray objectAtIndex:index]] highlightedImage:[UIImage imageNamed:[tabbarIconNamesArray objectAtIndex:index]] tag:index];
        navigation.tabBarItem = tempTabBarItem;
        [tempTabBarItem release];
        index++;
    }

    if (SYSTEM_VERSION_LESS_THAN(@"5.0")) {
        UIImageView * tabBarBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tabbar_background"]];
        tabBarBg.frame = CGRectMake(0, 0, 320, 50);
        tabBarBg.contentMode = UIViewContentModeScaleToFill;
        
        [self.tabBar insertSubview:tabBarBg atIndex:0];
        [tabBarBg release];
    }
    else
    {
        [self.tabBar setBackgroundImage:[UIImage imageNamed:@"tabbar_background"]];
    }
}
@end
