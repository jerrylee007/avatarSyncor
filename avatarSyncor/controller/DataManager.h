#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import "AddressBookManager.h"

@interface DataManager : NSObject{

}

+ (DataManager*) sharedManager;

@property (nonatomic, retain) AddressBookManager * abMannager;

- (void)handleLowMemory;


@end
/** @} */
