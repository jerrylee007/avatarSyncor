//
//  LoginViewController.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "iToast.h"
#import "SinaSDKManager.h"
#import "ViewConstants.h"
#import "ViewHelper.h"

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self.navigationItem setLeftBarButtonItem:[ViewHelper getBackBarItemOfTarget:self action:@selector(onBackButtonClicked) title:NSLocalizedString(@"go_back", @"go_back")]];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

- (void) onBackButtonClicked
{
    if (![self.navigationController popViewControllerAnimated:YES])
    {
        [self dismissModalViewControllerAnimated:YES];
    }
}

-(IBAction)onLoginPressed:(id)sender
{
    if (![[SinaSDKManager sharedManager] isLogin])
    {
        [[SinaSDKManager sharedManager] setRootviewController:self.navigationController];
        [[SinaSDKManager sharedManager] loginWithDoneCallback:^(LOGIN_STATUS status) {
            NSLog(@"Sina SDK login done, status:%d", status);
            if (status == LOGIN_STATUS_SUCCESS) {
                [self dismissModalViewControllerAnimated:YES];
                [[iToast makeText:@"亲，认证成功了！"] show];
                
//                [[SinaSDKManager sharedManager] sendWeiBoWithText:@"我刚刚用了<Avatar达人>同步sina微博好友的头像到iPhone联系人，很方便哦，你也试试吧! 下载地址:http://11232.com" image:nil doneCallback:^(AIO_STATUS status, NSDictionary *data) {
//                    
//                }];
                
                [[SinaSDKManager sharedManager] getMyUidWithDoneCallback:^(AIO_STATUS status, NSDictionary *data) {
                    NSString * uid = [data objectForKey:@"uid"];
                    if (uid) {
                        [[NSUserDefaults standardUserDefaults] setObject:uid forKey:USERDEFAULT_USER_UID];
                    }
                }];
            }
            else
            {
                [[iToast makeText:@"亲，认证失败了！"] show];
            }
        }];   
    }
    else
    {
        [[iToast makeText:@"亲，已经认证过了！"] show];
    }
}

@end
