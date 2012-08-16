//
//  viewConstants.h
//  avatarSyncor
//
//  Created by Jerry Lee on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef avatarSyncor_viewConstants_h
#define avatarSyncor_viewConstants_h

#define ADS_CELL_WIDTH              (320)
#define ADS_CELL_HEIGHT             (67)
#define ADS_PAGE_CONTROLLER_DOT_WIDTH             (5)

#define USER_INFOR_CELL_HEIGHT      (80)

#define TEXT_VIEW_MAX_CHARACTOR_NUMBER    140

#define CONTENT_MARGIN              (5.0)


#define NAVIGATION_LEFT_LOGO_WIDTH (90.0)
#define NAVIGATION_LEFT_LOGO_HEIGHT (27.0)

#define SCROLL_ITEM_MARGIN      (11.0)
#define SCROLL_ITEM_WIDTH       (66.0)
#define SCROLL_ITEM_HEIGHT      (66.0)

#define CATEGORY_TITLE_FONT_HEIGHT  (14.0f)
#define CATEGORY_TITLE_MARGIN  (14.0f)
#define CATEGORY_ITEM_HEIGHT  (CATEGORY_TITLE_FONT_HEIGHT + CATEGORY_TITLE_MARGIN + SCROLL_ITEM_HEIGHT)

#define SCREEN_WIDTH                ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT                ([[UIScreen mainScreen] bounds].size.height)

#define VERTICAL_SCROLL_VIEW_BOUNCE_SIZE (50.0)

#define TOOL_BAR_HEIGHT             (44.0)
#define NAVIGATION_BAR_HEIGHT       (44.0)
#define TAB_BAR_HEIGHT              (50.0)
#define STATUS_BAR_HEIGHT           (20.0)
#define TEXT_VIEW_MARGE_HEIGHT      (20.0)
// The height of the screen user could use. (Whole screen height minus navigation bar and tab bar)
#define USER_WINDOW_HEIGHT          (SCREEN_HEIGHT - NAVIGATION_BAR_HEIGHT - TAB_BAR_HEIGHT - STATUS_BAR_HEIGHT)

#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0)


#define APPDELEGATE ((AppDelegate*)([UIApplication sharedApplication].delegate))

#define APPDELEGATE_ROOTVIEW_CONTROLLER ((AppDelegate*)([UIApplication sharedApplication].delegate)).rootViewController

#define SYSTEM_VERSION_LESS_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


#define K_NOTIFICATION_SHOWWAITOVERLAY  @"K_NOTIFICATION_SHOWWAITOVERLAY"
#define K_NOTIFICATION_HIDEWAITOVERLAY  @"K_NOTIFICATION_HIDEWAITOVERLAY"

#define USERDEFAULT_USER_UID @"USERDEFAULT_USER_UID"
#endif
