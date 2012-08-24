/***********************************************************************
 *
 * Copyright (C) 2011-2012 Myriad Group AG. All Rights Reserved.
 *
 * File     :   $Id: //depot/ds/projects/MSSS/pivot_1.x/apps/Pivot/Pivot/Controller/AddressBookManager.m#2 $
 *
 ***********************************************************************/

/** \addtogroup CONTROLLER
 *  @{
 */

#import <UIKit/UIKit.h>
#import "AddressBookManager.h"
//#import "CachesManager.h"
#import <dispatch/dispatch.h>
#import <AddressBook/AddressBook.h>
#import "DataManager.h"
#import "ViewConstants.h"
#import "UIImageView+WebCache.h"
//#import "DataConstants.h"
//#import "DataHelper.h"
//#import "SDKHelper.h"

@interface ABContext : NSObject

@property (nonatomic,readonly) ABAddressBookRef abRef;

@end

@implementation ABContext
@synthesize abRef=_abRef;
- (void)dealloc {
    if (_abRef) {
        CFRelease(_abRef);
    }
    [super dealloc];
}

- (id)init {
    self = [super init];

    if (self) {
        _abRef = ABAddressBookCreate();
    }

    return self;
}

@end

@interface ABContextPool : NSObject {
@private
    NSMutableDictionary* queueABContexts;
}

- (ABContext*)getCurrentQueueABContext;
- (ABContext*)getQueueABContext:(dispatch_queue_t)queue;
@end

@implementation ABContextPool

- (void)dealloc {
    [queueABContexts release];
    [super dealloc];
}

- (id)init {
    self = [super init];

    if (self) {
        queueABContexts = [[NSMutableDictionary alloc]init];
    }

    return self;
}

- (void)clearPool {
    @synchronized(self) {
        //keep the main queue context, or ABChangeCallback become invalid after context free.
        ABContext *abContext = [[self getQueueABContext:nil] retain];
        [queueABContexts removeAllObjects];
        NSString *mainQueueName = [NSString stringWithUTF8String:dispatch_queue_get_label(dispatch_get_main_queue())];

        [queueABContexts setObject:abContext forKey:mainQueueName];
        [abContext release];
    }
}

- (ABContext*)getCurrentQueueABContext {
    return [self getQueueABContext:dispatch_get_current_queue()];
}

- (ABContext*)getQueueABContext:(dispatch_queue_t)queue{
    ABContext* context = nil;

    if (queue == nil) {
        queue = dispatch_get_main_queue();
    }

    @synchronized(self) {
        NSString *name = [NSString stringWithUTF8String:dispatch_queue_get_label(queue)];
        NSAssert(name != nil && ![name isEqual:@""], @"queue name must not be empty");

        context = [queueABContexts objectForKey:name];

        if (context == nil) {
            context = [[[ABContext alloc] init] autorelease];

            [queueABContexts setObject:context forKey:name];
        }
    }
    return context;
}
@end

@interface AddressBookManager ()
@property (nonatomic, readonly) ABRecordRef localSource;
@property (nonatomic, retain) ABContextPool* abContexts;
@property (nonatomic, assign) id bgObserver;
@property (nonatomic, assign) id fgObserver;

/**
 @brief Notifies the manager not to listen and report to delegate about changes.
 Use it when modifying adressbook data you don't want to be notified about inmediately (like adding addressbook contacts)

 @see startABChangeListener
 */
- (void)stopABChangeListener;

/**
 @brief Notifies the manager to listen and report to delegate about changes.

 @see stopABChangeListener
 */
- (void)startABChangeListener;

- (int)getNumberofMultivalueProps:(ABRecordID)record property:(ABPropertyType)type;
- (NSString*)getMultiStringValue:(ABRecordID)record property:(ABPropertyType)type index:(int)idx;
- (NSArray*)getAllMultiStringValues:(ABRecordID)record property:(ABPropertyType)type;
- (NSString *)getMultipleStringLabel:(ABRecordID)record property:(ABPropertyType)type index:(int)idx;
//- (NSDictionary *)getDictionaryForRecordId:(ABRecordID)recordId property:(ABPropertyType)type;
//- (CFStringRef)getABLabelFromString:(NSString *)labelStr forType:(ABPropertyID)type;
- (NSArray*)getAllMultiStringValuesWithRef:(ABAddressBookRef)person property:(ABPropertyType)type;
- (int)getNumberOfMultivaluePropsWithRef:(ABRecordRef)person property:(ABPropertyType)type;
- (NSString* )getStringValueOfRecord:(ABRecordID)record forProperty:(ABPropertyID)property;
- (BOOL)isEmptyContact:(ABRecordID)recordId;
//- (NSUInteger)maxSupportEmailCountForPerson:(ABRecordRef)person;

// The addressBook object does not take any action to flush or synchronize cached state with the Address Book database.
// use ABAddressBookRevert to ensure that addressBook doesn’t contain stale values
//- (void) refreshContexts;
- (UIImage *)getAvatarOfContact:(ABRecordID)record imageFormat:(ABPersonImageFormat)imageFormat;

@end

@implementation AddressBookManager
@synthesize sharedPeopleArray, delegate;
@synthesize abPhoneLabels = _abPhoneLabels;
@synthesize abEmailLabels = _abEmailLabels;
@synthesize bgObserver = _bgObserver;
@synthesize fgObserver = _fgObserver;
@synthesize abContexts;

#pragma mark -
#pragma mark C interface
static void ABChangeCallback(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    //NOTE: must call ABRefreshData to let main ad context to discard the stale data and load the latest data.
    AddressBookManager* abManager = (AddressBookManager *)context;
 //   [abManager refreshContexts];
    [[abManager delegate] addressBookDidChanged];
}

#pragma mark -
#pragma mark Init/dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.fgObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.bgObserver];
    [self stopABChangeListener];
    [sharedPeopleArray release];
    [abContexts release];
    [_abPhoneLabels release];
    [_abEmailLabels release];

    [super dealloc];
}

- (id) init {
    self = [super init];

    if (self) {
        abContexts = [[ABContextPool alloc]init];
        sharedPeopleArray = [[NSArray alloc]init];

        //We don't want to leave any data related to BG save queue pending and retained when going to background.
        //Specially accessing AddressBook API, we need to release it when going to background. this listener to
        //bg notification releases queues so they will be destroyed as soon as operations in blocks finished.
        self.bgObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note) {
                                                          //Release all AB contexts. If retained by any thread,
                                                          //they will be still in memory.
                                                          [abContexts clearPool];
                                                          // only interested in the changed in background.
                                                          [self startABChangeListener];
                                                      }];
        self.fgObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note) {
                                                          // not interesting on AB changed notification at foreground,
                                                          // becuase it's likely fired by pivot itself.
                                                          //NOTE: wait a while to let ABChangeCallback is delivered correctly after foreground&background switching.
                                                          //FIXME: which delay interval is properly?
                                                          [self performSelector:@selector(stopABChangeListener) withObject:self afterDelay:1.0f];
                                                      }];
    }

    return self;
}

- (void)stopABChangeListener {
    ABContext* mainContext = (ABContext*)[[abContexts getQueueABContext:nil] retain];
    if (dispatch_get_current_queue() == dispatch_get_main_queue()){
        ABAddressBookUnregisterExternalChangeCallback(mainContext.abRef,ABChangeCallback,self);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            ABAddressBookUnregisterExternalChangeCallback(mainContext.abRef,ABChangeCallback,self);
        });
    }
    //Release Address Book context
    [mainContext release];
}

- (void)startABChangeListener {
    ABContext* mainContext = (ABContext*)[[abContexts getQueueABContext:nil] retain];
    if (dispatch_get_current_queue() == dispatch_get_main_queue()){
        ABAddressBookRegisterExternalChangeCallback(mainContext.abRef,ABChangeCallback,self);
    } else {
        // use dispatch_sync instead of dispatch_async to make sure registercallback is done.
        dispatch_sync(dispatch_get_main_queue(), ^{
            ABAddressBookRegisterExternalChangeCallback(mainContext.abRef,ABChangeCallback,self);
        });
    }
//    [self refreshContexts];
    //Release Address Book context
    [mainContext release];
}

////refresh context in other queue
//- (void) refreshContextInQueue:(dispatch_queue_t)queue {
//    if (dispatch_get_current_queue() == queue){
//        ABAddressBookRevert([abContexts getQueueABContext:queue].abRef);
//    }
//    else {
//        dispatch_async(queue, ^{
//            ABAddressBookRevert([abContexts getQueueABContext:queue].abRef);
//        });
//    }
//}
//
//- (void) refreshContexts {
//    [self refreshContextInQueue:dispatch_get_main_queue()];
////  [self refreshContextInQueue:[CachesManager getQueue]];
////    [self refreshContextInQueue:[CoreDataManager getQueue]];
//}

#pragma mark - Public API

//- (ABRecordID)addContactToAddressBookWithPhones:(NSArray *)phones
//                          withPhoneLabels:(NSArray *)phoneLabels
//                               withEmails:(NSArray *)emails
//                          withEmailLabels:(NSArray *)emailLabels
//                               withAvatar:(id)avatarData
//                             withBirthday:(NSString *)birthday
//                           withFamilyName:(NSString *)familyName
//                            withGivenName:(NSString *)givenName
//                   withPhoneticFamilyName:(NSString *)phoneticFamilyName
//                    withPhoneticGivenName:(NSString *)phoneticGivenName {
//    NSAssert2([phones count] == [phoneLabels count], @"phones and phone labels must match %@, %@", phones, phoneLabels);
//    NSAssert2([emails count] == [emailLabels count], @"email and email labels must match %@, %@", emails, emailLabels);
//    ABRecordID recordId = NULL;
//
//    // create contact
//    CFErrorRef error = NULL;
//    ABContext* context = [[abContexts getCurrentQueueABContext] retain];
//    ABAddressBookRef ab = context.abRef;
//    // Native addressbook app supports multiple sources, some of them have limitation,
//    // for example, Exchange only support 3 emails at most.
//    // To avoid that kind of potential issues, create record to local source with priority.
//    ABRecordRef preferredSource = self.localSource;
//    ABRecordRef newPerson = preferredSource ? ABPersonCreateInSource(preferredSource)
//                                            : ABPersonCreate();
//
//    // single value fields
//    //update family name
//    if (![DataHelper isEmptyText:familyName]) {
//        ABRecordSetValue(newPerson, kABPersonLastNameProperty, (CFStringRef)familyName, NULL);
//    }
//
//    //update given name
//    if (![DataHelper isEmptyText:givenName]) {
//        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (CFStringRef)givenName, NULL);
//    }
//
//    //update the phonetic of the family name
//    if (![DataHelper isEmptyText:phoneticFamilyName]) {
//        ABRecordSetValue(newPerson, kABPersonLastNamePhoneticProperty, (CFStringRef)phoneticFamilyName, NULL);
//    }
//
//    //update the phonetic of the given name
//    if (![DataHelper isEmptyText:phoneticGivenName]) {
//        ABRecordSetValue(newPerson, kABPersonFirstNamePhoneticProperty, (CFStringRef)phoneticGivenName, NULL);
//    }
//
//    if ([emails count] > 0) {
//        ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//        for (int i = 0; i < [emails count]; i++){
//            CFStringRef label = [self getABLabelFromString:[emailLabels objectAtIndex:i] forType:kABPersonEmailProperty];
//            ABMultiValueAddValueAndLabel(multiEmail, (CFStringRef) [emails objectAtIndex:i], label, NULL);
//
//        }
//        // setting & cleaning
//        if (multiEmail){
//            ABRecordSetValue(newPerson, kABPersonEmailProperty, multiEmail, nil);
//            CFRelease(multiEmail);
//        }
//    }
//
//    // TODO: get NSDate from url
//    // set image to address book after retrieving it
//    //    NSString *imageURL = [contactData objectForMGKey:MG_TK_SN_ApplicationObjectKeys::KEY_IMAGE_URI];
//    if ([phones count] > 0) {
//        ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//        for (int i = 0; i < [phones count]; i++){
//            CFStringRef label = [self getABLabelFromString:[phoneLabels objectAtIndex:i] forType:kABPersonPhoneProperty];
//            ABMultiValueAddValueAndLabel(multiPhone, (CFStringRef) [phones objectAtIndex:i], label, NULL);
//        }
//
//        // setting & cleaning
//        if (multiPhone) {
//            ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone, nil);
//            CFRelease(multiPhone);
//        }
//    }
//
//    if (avatarData != nil) {
//        if ([avatarData isKindOfClass:[NSNull class]]){
//            ABPersonSetImageData(newPerson, NULL, &error);
//        }   else {
//            ABPersonSetImageData(newPerson, (CFDataRef)avatarData, &error);
//        }
//    }
//
//    // setting birthday
//    NSDate *bdDate = [DataHelper dateFromFixedFormatString:birthday];
//    if (bdDate) {
//        CFDateRef bd = (CFDateRef)bdDate;
//        ABRecordSetValue(newPerson, kABPersonBirthdayProperty, bd, NULL);
//    }
//
//    // save contact
//    if (ABAddressBookAddRecord(ab, newPerson, &error)) {
//        ABAddressBookSave(ab, &error);
//        recordId = ABRecordGetRecordID(newPerson);
//    }
//
//    // cleaning
//    CFRelease(newPerson);
//
//    if (error != NULL) {
//        CFStringRef errorDesc = CFErrorCopyDescription(error);
//        NSLog(@"Contact not saved: %@", errorDesc);
//        CFRelease(errorDesc);
//        recordId = NULL;
//    }
//
//    [context release];
//    return recordId;
//}

- (void)updateABRecord:(ABRecordID)record withAvatarData:(NSData *)data {
    [self stopABChangeListener];

    CFErrorRef error = NULL;
    ABContext* context = [[abContexts getCurrentQueueABContext] retain];
    ABAddressBookRef ab = context.abRef;
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab, record);

    if (person) {
        //always replace AB image with Server data...
        if (ABPersonHasImageData(person)) {
            ABPersonRemoveImageData(person, &error);
            NSAssert1(error == nil, @"GET a error during ABPersonRemoveImageData %@", error);
        }
        ABPersonSetImageData(person, (CFDataRef)data, &error);
        bool save = ABAddressBookSave(ab, &error);
        if (!save) {
            NSAssert(NO, @"UPDATE Avatar: Problem with saving contact to native address book");
        }
    }
    //Release Address Book context
    [context release];

    [self startABChangeListener];
}

- (void)updateABRecord:(ABRecordID)record withAvatarUrl:(NSString *)url
{
    UIImageView * fackImageView = [[UIImageView alloc] init];
    
    [fackImageView setImageWithURL:[NSURL URLWithString:url] success:^(UIImage *image) {
        [self updateABRecord:record withAvatarData:UIImageJPEGRepresentation(image, 1.0)];
        
    } failure:^(NSError *error) {
        
    }];
}

- (NSArray*)getAllABRecordIds {
    //Get all people in array
    ABContext* context = (ABContext*)[[abContexts getCurrentQueueABContext] retain];
    NSArray* peoples = (NSArray*)ABAddressBookCopyArrayOfAllPeople(context.abRef);

    NSMutableArray* ids = [[NSMutableArray alloc] initWithCapacity:[peoples count]];

    //LOOP - Fill array with record Ids
    for (id contact in peoples) {
        ABRecordID abRecord = ABRecordGetRecordID(contact);

        // empty contact make no sense to us, though, it may exist on NAB.
        if (![self isEmptyContact:abRecord]) {
            [ids addObject:[NSNumber numberWithInt:abRecord]];
        } else {
            NSLog(@"A contact(id = %d) owns no name, email, phone or birthday!", abRecord);
        }
    }//LOOP END

    if (peoples) {
        CFRelease(peoples);
    }

    //Release Address Book context
    [context release];
    return [ids autorelease];
}

- (BOOL)hasContactAvatar:(ABRecordID)record {
    BOOL has = NO;
    ABContext* context = [[abContexts getCurrentQueueABContext] retain];
    ABAddressBookRef ab = context.abRef;

    if (record != kABRecordInvalidID)
    {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        if (person)
        {
            has = ABPersonHasImageData(person);
        }
    }

    //Release Address Book context
    [context release];
    return has;
}

- (UIImage *)getAvatarOfContact:(ABRecordID)record imageFormat:(ABPersonImageFormat)imageFormat {
    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = context.abRef;
    UIImage* image = nil;

    if (record != kABRecordInvalidID) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        if (person) {
            if (ABPersonHasImageData(person)) {
                CFDataRef imageData = ABPersonCopyImageDataWithFormat(person, imageFormat);
                if (imageData) {
                    image = [UIImage imageWithData:(NSData *)imageData];
                    CFRelease(imageData);
                }
            }
        }
    }

    //Release Address Book context
    [context release];
    return image;
}

- (UIImage *)getAvatarOfContact:(ABRecordID)record {
    return [self getAvatarOfContact:record imageFormat:kABPersonImageFormatThumbnail];
}

- (UIImage *)getFullSizeAvatarOfContact:(ABRecordID)record {
    return [self getAvatarOfContact:record imageFormat:kABPersonImageFormatOriginalSize];
}

- (NSString *) getNameOfContactWithRef:(ABRecordRef)person {
    NSString* contactName = nil;

    if (person) {
        CFStringRef compName = ABRecordCopyCompositeName(person);
        if (compName) {
            contactName = [[(NSString *)compName retain]autorelease];
            CFRelease(compName);
        }
    }

    return contactName;
}

- (NSString *) getNameOfContact:(ABRecordID)record {
    NSString* contactName = nil;

    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = context.abRef;

    if (record != kABRecordInvalidID) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        contactName = [self getNameOfContactWithRef:person];
    }

    //Release Address Book context
    [context release];

    return contactName;
}

- (NSDate*)getBirthDayDateOfContact:(ABRecordID)record {
    NSDate* birthDate = nil;

    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = context.abRef;

    if (record != kABRecordInvalidID)
    {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        if (person)
        {
            CFDateRef bd = (CFDateRef)ABRecordCopyValue(person, kABPersonBirthdayProperty);
            if (bd) {
                birthDate = [[(NSDate *)bd retain] autorelease];
                CFRelease(bd);
            }
        }
    }

    //Release Address Book context
    [context release];

    return birthDate;
}

- (NSString* )getFamilyNameOfContact:(ABRecordID)record {
    return [self getStringValueOfRecord:record forProperty:kABPersonLastNameProperty];
}

- (NSString* )getGivenNameOfContact:(ABRecordID)record {
    return [self getStringValueOfRecord:record forProperty:kABPersonFirstNameProperty];
}

- (NSString* )getPhoneticFamilyNameOfContact:(ABRecordID)record {
    return [self getStringValueOfRecord:record forProperty:kABPersonLastNamePhoneticProperty];
}

- (NSString* )getPhoneticGivenNameOfContact:(ABRecordID)record {
    return [self getStringValueOfRecord:record forProperty:kABPersonFirstNamePhoneticProperty];
}

- (int)getNumberofTNFieldsOfContact:(ABRecordID)record {
    return [self getNumberofMultivalueProps:record property:kABPersonPhoneProperty];
}

- (NSString *)getTnForContact:(ABRecordID)record atIndex:(int)idx{
    return [self getMultiStringValue:record property:kABPersonPhoneProperty index:idx];
}

- (NSArray *)getAllTnForContact:(ABRecordID)record {
    return [self getAllMultiStringValues:record property:kABPersonPhoneProperty];
}

- (int)getNumberofEmailsOfContact:(ABRecordID)record {
    return [self getNumberofMultivalueProps:record property:kABPersonEmailProperty];
}

- (NSString *)getEmailForContact:(ABRecordID)record atIndex:(int)idx {
    return [self getMultiStringValue:record property:kABPersonEmailProperty index:idx];
}

- (NSString *)getEmailLabelForContact:(ABRecordID)record atIndex:(int)idx {
    return [self getMultipleStringLabel:record property:kABPersonEmailProperty index:idx];
}

- (NSArray *)getAllEmailForContact:(ABRecordID)record {
    return [self getAllMultiStringValues:record property:kABPersonEmailProperty];
}

- (NSString *)getPhoneForContact:(ABRecordID)record atIndex:(int)idx {
    return [self getMultiStringValue:record property:kABPersonPhoneProperty index:idx];
}

- (NSString *)getPhoneLabelForContact:(ABRecordID)record atIndex:(int)idx {
    return [self getMultipleStringLabel:record property:kABPersonPhoneProperty index:idx];
}

- (NSDate *)getUpdateDateForContact:(ABRecordID)record {

    NSDate* updateTime = nil;
    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = context.abRef;

    if (record != kABRecordInvalidID) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        if (person) {
            CFDateRef bd = (CFDateRef)ABRecordCopyValue(person, kABPersonModificationDateProperty);
            if (bd) {
                updateTime = [[(NSDate *)bd retain] autorelease];
                CFRelease(bd);
            }
        }
    }

    //Release Address Book context
    [context release];

    return updateTime;
}

//- (BOOL)isEqualABContactSimpleField:(ABPropertyID)property
//                            withRef:(ABRecordRef)person
//                     withServerDataValue:(NSString *)serverDataValue {
//    BOOL isEqual = NO;
//
//    if (property == kABPersonFirstNameProperty
//        || property == kABPersonLastNameProperty
//        || property == kABPersonFirstNamePhoneticProperty
//        || property == kABPersonLastNamePhoneticProperty) {
//        NSString *serverName = serverDataValue;
//        NSString *localName = (NSString *)ABRecordCopyValue(person, property);
//
//        isEqual = [DataHelper isEqualString:serverName to:localName];
//
//        [localName release];
//    } else if (property == kABPersonBirthdayProperty) {
//        CFDateRef bdLocalRef = (CFDateRef)ABRecordCopyValue(person, kABPersonBirthdayProperty);
//        NSDate *bdLocal = [[(NSDate*)bdLocalRef retain] autorelease];
//        if (bdLocalRef != NULL) {
//            CFRelease(bdLocalRef);
//        }
//        NSString *bdLocalStr = [DataHelper fixedFormatStringFromDate:bdLocal];
//
//        isEqual = [DataHelper isEqualString:bdLocalStr to:serverDataValue];
//    } else {
//        NSAssert1(NO, @"Unsupport ABContactField %d for comparision", property);
//    }
//
//    return isEqual;
//}
//
//- (BOOL)isEqualABContactWithRef:(ABRecordRef)person
//                     WithPhones:(NSArray*)phones
//                 withPhoneLabels:(NSArray*)phoneLabels
//                      withEmails:(NSArray*)emails
//                 withEmailLabels:(NSArray*)emailLabels
//                      withAvatar:(id)avatar
//                    withBirthday:(NSString *)birthday
//                  withFamilyName:(NSString *)familyName
//                   withGivenName:(NSString *)givenName
//          withPhoneticFamilyName:(NSString *)phoneticFamilyName
//           withPhoneticGivenName:(NSString *)phoneticGivenName {
//    // check all fields, interrupt when sth won't match
//    BOOL isEqual = YES;
//
//    // check family name.
//    isEqual = [self isEqualABContactSimpleField:kABPersonFirstNameProperty withRef:person withServerDataValue:familyName];
//
//    // continue check given name.
//    if (isEqual) {
//        isEqual = [self isEqualABContactSimpleField:kABPersonLastNameProperty withRef:person withServerDataValue:givenName];
//    }
//
//    // continue check phonetic family name.
//    if (isEqual) {
//        isEqual = [self isEqualABContactSimpleField:kABPersonFirstNamePhoneticProperty withRef:person withServerDataValue:phoneticFamilyName];
//    }
//
//    // continue check phonetic given name.
//    if (isEqual) {
//        isEqual = [self isEqualABContactSimpleField:kABPersonLastNamePhoneticProperty withRef:person withServerDataValue:phoneticGivenName];
//    }
//
//    // continue check mail & phone
//    if (isEqual) {
//        // TODO: comparing is not taking into account email & phone numbers labels
//        // PHONE
//        NSArray *phoneNumberServer = phones;
//        int phonesCount = [self getNumberOfMultivaluePropsWithRef:person property:kABPersonPhoneProperty];
//        isEqual = (phonesCount == [phoneNumberServer count]);
//
//        if (isEqual) {
//            NSArray* phoneNumbersLocal = [self getAllMultiStringValuesWithRef:person property:kABPersonPhoneProperty];
//
//            NSArray *sortedPhonesLocal = [phoneNumbersLocal sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//            NSArray *sortedPhonesServer = [phoneNumberServer sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//
//            isEqual = [sortedPhonesLocal isEqualToArray:sortedPhonesServer];
//        }
//
//        if (isEqual) {
//            // EMAIL
//            // TODO: comparing is not taking into account email & phone numbers labels
//            NSArray *emailsServer = emails;
//            int emailsCounter = [self getNumberOfMultivaluePropsWithRef:person property:kABPersonEmailProperty];
//            isEqual = (emailsCounter == [emailsServer count]);
//
//            if (isEqual) {
//                NSArray* emailsLocal = [self getAllMultiStringValuesWithRef:person property:kABPersonEmailProperty];
//
//                // sort arrays
//                NSArray *sortedEmailsLocal = [emailsLocal sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//                NSArray *sortedEmailsServer = [emailsServer sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//
//                isEqual = [sortedEmailsLocal isEqualToArray:sortedEmailsServer];
//            }
//        }
//    }
//
//    // continue check birthday.
//    if (isEqual) {
//        isEqual = [self isEqualABContactSimpleField:kABPersonBirthdayProperty withRef:person withServerDataValue:birthday];
//    }
//
//    // continue check image with imageHash for server.
//    // do not do this check if the Contact dictionary is come from server.
//    if (isEqual && avatar != nil) {
//        NSString *avatarHashServer = nil;
//        NSString *avatarHashLocal = nil;
//        if (![avatar isKindOfClass:[NSNull class]]){
//            avatarHashServer = [DataHelper MD5OfData:avatar];
//        }
//        if (ABPersonHasImageData(person)) {
//            CFDataRef imageData = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
//            if (imageData) {
//                // forcely convert to PNG representation to generate imageHash for comparision,
//                // since the imageHash generated on updatePhoneIdentity is PNG representation as well.
//                UIImage *image = [UIImage imageWithData:(NSData *)imageData];
//                NSData *pngImageData = UIImagePNGRepresentation(image);
//                CFRelease(imageData);
//
//                avatarHashLocal = [DataHelper MD5OfData:(NSData *)pngImageData];
//            }
//        }
//        isEqual = [DataHelper isEqualString:avatarHashServer to:avatarHashLocal];
//    }
//
//    return isEqual;
//}
//
//- (void)updateABRecord:(ABRecordID)record
//            WithPhones:(NSArray *)phones
//       withPhoneLabels:(NSArray *)phoneLabels
//            withEmails:(NSArray *)emails
//       withEmailLabels:(NSArray *)emailLabels
//            withAvatar:(id)avatar
//          withBirthday:(NSString *)birthday
//        withFamilyName:(NSString *)familyName
//         withGivenName:(NSString *)givenName
//withPhoneticFamilyName:(NSString *)phoneticFamilyName
// withPhoneticGivenName:(NSString *)phoneticGivenName
//             overwrite:(BOOL)overwrite {
//    NSAssert2([phones count] == [phoneLabels count], @"phones and phone labels must match %@, %@", phones, phoneLabels);
//    NSAssert2([emails count] == [emailLabels count], @"email and email labels must match %@, %@", emails, emailLabels);
//    // get contact
//    ABContext* context = [[abContexts getCurrentQueueABContext] retain];
//    ABAddressBookRef ab = context.abRef;
//    ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab, record);
//    //FIXME: once defined, should handle gracefully all separate fields for first name, last name etc. For now if displayName is (by chance)
//    //the same, then we merge it.
//
//    if (person == NULL) {
//        NSAssert1(NO, @"MERGING: No contact in native address book with ID %d", record);
//    }
//
//    if (avatar != nil) {
//        if ([avatar isKindOfClass:[NSNull class]]){
//            ABPersonSetImageData(person, NULL, NULL);
//        } else {
//            ABPersonSetImageData(person, (CFDataRef) avatar, NULL);
//        }
//    }
//
//    if (overwrite) {
//        // delete all old data
//        ABRecordRemoveValue(person, kABPersonEmailProperty, NULL);
//        ABRecordRemoveValue(person, kABPersonPhoneProperty, NULL);
//        ABRecordRemoveValue(person, kABPersonBirthdayProperty, NULL);
//    }
//
//    // update birthday
//    NSDate *bdDate = [DataHelper dateFromFixedFormatString:birthday];
//
//    if (bdDate) {
//        CFDateRef bd = (CFDateRef)bdDate;
//        ABRecordSetValue(person, kABPersonBirthdayProperty, bd, NULL);
//    }
//
//    //NOTE: don't allow save the name as empty text because it's not consistent with the behavior of native address book app which have no way to input empty text
//
//    if ([DataHelper isEmptyText:familyName]) {
//        familyName = nil;
//    }
//    ABRecordSetValue(person, kABPersonLastNameProperty, (CFStringRef)familyName, NULL);
//
//    //update given name
//    if ([DataHelper isEmptyText:givenName]) {
//        givenName = nil;
//    }
//    ABRecordSetValue(person, kABPersonFirstNameProperty, (CFStringRef)givenName, NULL);
//
//    //update the phonetic of the family name
//    if ([DataHelper isEmptyText:phoneticFamilyName]) {
//        phoneticFamilyName = nil;
//    }
//    ABRecordSetValue(person, kABPersonLastNamePhoneticProperty, (CFStringRef)phoneticFamilyName, NULL);
//
//    //update the phonetic of the given name
//    if ([DataHelper isEmptyText:phoneticGivenName]) {
//        phoneticGivenName = nil;
//    }
//    ABRecordSetValue(person, kABPersonFirstNamePhoneticProperty, (CFStringRef)phoneticGivenName, NULL);
//
//    // update email & phone
//
//    ABMultiValueRef tempMultiEmail = ABRecordCopyValue(person, kABPersonEmailProperty);
//    ABMutableMultiValueRef multiEmail = NULL;
//    // create a new one if have no local email
//    if (tempMultiEmail == NULL) {
//        multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//    } else {
//        multiEmail = ABMultiValueCreateMutableCopy(tempMultiEmail);
//        CFRelease(tempMultiEmail);
//    }
//
//    ABMultiValueRef tempMultiPhone = ABRecordCopyValue(person, kABPersonPhoneProperty);
//    ABMutableMultiValueRef multiPhone = NULL;
//    // create a new one if have no local phone
//    if (tempMultiPhone == NULL) {
//        multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//    } else {
//        multiPhone = ABMultiValueCreateMutableCopy(tempMultiPhone);
//        CFRelease(tempMultiPhone);
//    }
//
//    if (multiPhone == NULL || multiEmail == NULL) {
//        NSAssert(NO, @"MERGING: Problem with creating MultiValue record");
//    }
//
//    NSArray *emailsLocal = nil;
//    NSArray *phoneNumbersLocal = nil;
//
//    // EMAIL & PHONE arrays
//    if (!overwrite) {
//        phoneNumbersLocal = [self getAllMultiStringValuesWithRef:person property:kABPersonPhoneProperty];
//        emailsLocal = [self getAllMultiStringValuesWithRef:person property:kABPersonEmailProperty];
//    }
//
//    // EMAIL
//    // Workaround:
//    // Have to break out, if continue adding value-label pairs to ABMutableMultiValueRef after reach the
//    // max support count for kABPersonEmailProperty. AB will discard the whole ABMutableMultiValueRef.
//    // Aka, return false on subsequent ABRecordSetValue.
//    int maxCount = [self maxSupportEmailCountForPerson:person];
//    int emailCount = MIN([emails count], maxCount);
//    for(int i = 0; i < emailCount; i++){
//        // add server email to local if not found
//        if (emailsLocal == nil || ![emailsLocal containsObject:[emails objectAtIndex:i]]) {
//            CFStringRef label = [self getABLabelFromString:[emailLabels objectAtIndex:i] forType:kABPersonEmailProperty];
//            ABMultiValueAddValueAndLabel(multiEmail, (CFStringRef)[emails objectAtIndex:i], label, NULL);
//        }
//    };
//
//    // PHONE
//    for(int i = 0; i < [phones count]; i++){
//        // add server phone to local if not found
//        if (phoneNumbersLocal == nil || ![phoneNumbersLocal containsObject:[phones objectAtIndex:i]]) {
//            CFStringRef label = [self getABLabelFromString:[phoneLabels objectAtIndex:i] forType:kABPersonPhoneProperty];
//            ABMultiValueAddValueAndLabel(multiPhone, (CFStringRef)[phones objectAtIndex:i], label, NULL);
//        }
//    }
//
//    ABRecordSetValue(person, kABPersonEmailProperty, multiEmail, nil);
//    ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone, nil);
//
//    bool save = ABAddressBookSave(ab, NULL);
//
//    CFRelease(multiPhone);
//    CFRelease(multiEmail);
//    [context release];
//
//    if (!save) {
//        NSAssert(NO, @"MERGING: Problem with saving contact to native address book");
//    }
//}
//
//- (BOOL)mergeIdentity:(int)nabId
//           WithPhones:(NSArray *)phones
//      withPhoneLabels:(NSArray *)phoneLabels
//           withEmails:(NSArray *)emails
//      withEmailLabels:(NSArray *)emailLabels
//           withAvatar:(id)avatar
//         withBirthday:(NSString *)birthday
//       withFamilyName:(NSString *)familyName
//        withGivenName:(NSString *)givenName
//withPhoneticFamilyName:(NSString *)phoneticFamilyName
//withPhoneticGivenName:(NSString *)phoneticGivenName
//           overwrite:(BOOL)overwrite {
//    NSAssert2([phones count] == [phoneLabels count], @"phones and phone labels must match %@, %@", phones, phoneLabels);
//    NSAssert2([emails count] == [emailLabels count], @"email and email labels must match %@, %@", emails, emailLabels);
//
//    BOOL hasContactBeenChange = NO;
//    // get contact
//    ABContext* context = [[abContexts getCurrentQueueABContext] retain];
//    ABAddressBookRef ab = context.abRef;
//    ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab, nabId);
//
//    BOOL areContactEqual = [self isEqualABContactWithRef:person
//                                              WithPhones:phones
//                                         withPhoneLabels:phoneLabels
//                                              withEmails:emails
//                                         withEmailLabels:emailLabels
//                                              withAvatar:avatar
//                                            withBirthday:birthday
//                                          withFamilyName:familyName
//                                           withGivenName:givenName
//                                  withPhoneticFamilyName:phoneticFamilyName
//                                   withPhoneticGivenName:phoneticGivenName];
//
//    if (!areContactEqual) {
//        [self updateABRecord:nabId
//                  WithPhones:phones
//             withPhoneLabels:phoneLabels
//                  withEmails:emails
//             withEmailLabels:emailLabels
//                  withAvatar:avatar
//                withBirthday:birthday
//              withFamilyName:familyName
//               withGivenName:givenName
//      withPhoneticFamilyName:phoneticFamilyName
//       withPhoneticGivenName:phoneticGivenName
//                   overwrite:overwrite];
//        hasContactBeenChange = YES;
//    }
//
//    [context release];
//    return hasContactBeenChange;
//}

-(void)deleteABRecord:(ABRecordID)record {
    ABAddressBookRef ab = [abContexts getCurrentQueueABContext].abRef;

    if (record != kABRecordInvalidID) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab, record);
        if (person) {
            ABAddressBookRemoveRecord (ab, person, nil);
            ABAddressBookSave(ab, NULL);
        }
    }
};

//- (NSArray *)abPhoneLabels {
//    if (_abPhoneLabels == nil) {
//        // Record all supported phone labels(exclude user-defined labels)
//        // to keep consistent with native addressbook app on label display.
//        float iOSVersion = [SDKHelper iOSVersion];
//        // Property type kABPersonPhoneOtherFAXLabel is added on iOS5.0, lower version do not support it.
//        if (iOSVersion >= 5.0) {
//            _abPhoneLabels = [[NSArray alloc] initWithObjects:(NSString *)kABPersonPhoneMobileLabel,
//                              (NSString *)kABPersonPhoneIPhoneLabel,
//                              (NSString *)kABHomeLabel,
//                              (NSString *)kABWorkLabel,
//                              (NSString *)kABPersonPhoneMainLabel,
//                              (NSString *)kABPersonPhoneHomeFAXLabel,
//                              (NSString *)kABPersonPhoneWorkFAXLabel,
//                              (NSString *)kABPersonPhoneOtherFAXLabel,
//                              (NSString *)kABPersonPhonePagerLabel,
//                              (NSString *)kABOtherLabel, nil];
//        } else {
//            _abPhoneLabels = [[NSArray alloc] initWithObjects:(NSString *)kABPersonPhoneMobileLabel,
//                              (NSString *)kABPersonPhoneIPhoneLabel,
//                              (NSString *)kABHomeLabel,
//                              (NSString *)kABWorkLabel,
//                              (NSString *)kABPersonPhoneMainLabel,
//                              (NSString *)kABPersonPhoneHomeFAXLabel,
//                              (NSString *)kABPersonPhoneWorkFAXLabel,
//                              (NSString *)kABPersonPhonePagerLabel,
//                              (NSString *)kABOtherLabel, nil];
//        }
//    }
//
//    return  _abPhoneLabels;
//}

- (NSArray *)abEmailLabels {
    if (_abEmailLabels == nil) {
        // Record all supported email labels(exclude user-defined labels)
        // to keep consistent with native addressbook app on label display.
        _abEmailLabels = [[NSArray alloc] initWithObjects:(NSString *)kABHomeLabel,
                                                          (NSString *)kABWorkLabel,
                                                          (NSString *)kABOtherLabel, nil];
    }

    return  _abEmailLabels;
}

- (ABRecordRef)localSource {
    ABRecordRef ret = NULL;

    ABContext* context = [[abContexts getCurrentQueueABContext] retain];
    ABAddressBookRef ab = context.abRef;

    CFArrayRef sources = ABAddressBookCopyArrayOfAllSources(ab);
    CFIndex sourceCount = CFArrayGetCount(sources);

    for (CFIndex i = 0; i < sourceCount && ret == NULL; i++) {
        ABRecordRef currentSource = CFArrayGetValueAtIndex(sources, i);
        CFTypeRef sourceType = ABRecordCopyValue(currentSource, kABSourceTypeProperty);

        if (kABSourceTypeLocal == [(NSNumber *)sourceType intValue]) {
            ret = currentSource;
        }

        CFRelease(sourceType);
    }

    CFRelease(sources);
    [context release];

    // Do not record the localSource into a variable, since different threads
    // may go here, and the source reference is not across-threads safe.
    return ret;
}

#pragma mark - Get Phone & Email Dictionaries For Server Upload
//- (NSDictionary *)getEmailsDictionaryForRecordId:(ABRecordID)recordId {
//    return [self getDictionaryForRecordId:recordId property:kABPersonEmailProperty];
//}
//
//- (NSDictionary *)getPhoneNumbersDictionaryForRecordId:(ABRecordID)recordId {
//    return [self getDictionaryForRecordId:recordId property:kABPersonPhoneProperty];
//}
//
//- (NSDictionary *)getDictionaryForRecordId:(ABRecordID)recordId property:(ABPropertyType)type {
//    NSMutableDictionary *resultDict = [[[NSMutableDictionary alloc] initWithCapacity:30] autorelease];
//
//    int fieldCounter = 0;
//    if (type == kABPersonPhoneProperty) {
//        fieldCounter = [self getNumberofTNFieldsOfContact:recordId];
//    } else {
//        fieldCounter = [self getNumberofEmailsOfContact:recordId];
//    }
//
//    // we are syncing only 5
//    fieldCounter = MIN(fieldCounter, MAX_NUMBER_OF_SYNC_FIELDS);
//
//    for (int i=0; i<fieldCounter; i++) {
//        NSString *key = [self getMultipleStringLabel:recordId property:type index:i];
//        NSString *value = [self getMultiStringValue:recordId property:type index:i];
//
//        // In some special cases, the label returned from AB api is nil,
//        // for example, there is no label for email item on iOS version which lower than 4.3.
//        // So, has to handle them specially.
//        if ([DataHelper isEmptyText:key]) {
//            LOG_WARNING_SYS(@"Empty key for recordId(%d) at index(%d), its value is %@", recordId, i, value);
//
//            // Ignore item which do not owns a label.
//            continue;
//        }
//
//        if ([resultDict objectForKey:key]) {
//            NSString *newValue = [NSString stringWithFormat:@"%@,%@", [resultDict objectForKey:key], value];
//
//            [resultDict setObject:newValue forKey:key];
//        } else {
//            [resultDict setObject:value forKey:key];
//        }
//    }
//
//    return resultDict;
//}
//
#pragma mark -
#pragma mark Private interface

- (int)getNumberOfMultivaluePropsWithRef:(ABRecordRef)person property:(ABPropertyType)type {
    int num = 0;

    if (person) {
        ABMultiValueRef propMulti = ABRecordCopyValue(person,type);
        if (propMulti) {
            num = ABMultiValueGetCount(propMulti);
            CFRelease(propMulti);
        }
    }
    return num;
}


- (int)getNumberofMultivalueProps:(ABRecordID)record property:(ABPropertyType)type {
    int num = 0;

    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = context.abRef;

    if (record != kABRecordInvalidID) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        num = [self getNumberOfMultivaluePropsWithRef:person property:type];
    }

    //Release Address Book context
    [context release];

    return num;
}

- (NSString*)getMultiStringValue:(ABRecordID)record property:(ABPropertyType)type index:(int)idx {
    NSString* value = nil;

    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = context.abRef;

    if (record != kABRecordInvalidID)
    {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        if (person) {
            ABMultiValueRef propMulti = ABRecordCopyValue(person,type);
            if (propMulti) {
                int num = ABMultiValueGetCount(propMulti);
                if (idx < num) {
                    CFStringRef strRef = (CFStringRef)ABMultiValueCopyValueAtIndex(propMulti, idx);
                    if (strRef) {
                        value = [NSString stringWithString:(NSString*)strRef];
                        CFRelease(strRef);
                    }
                }
                CFRelease(propMulti);
            }
        }
    }

    //Release Address Book context
    [context release];
    return value;
}


- (NSString *)getMultipleStringLabel:(ABRecordID)record property:(ABPropertyType)type index:(int)idx {
    NSString* value = nil;

    ABContext* threadAB = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = threadAB.abRef;

    if (record != kABRecordInvalidID) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        if (person) {
            ABMultiValueRef propMulti = ABRecordCopyValue(person,type);
            if (propMulti) {
                int num = ABMultiValueGetCount(propMulti);
                if (idx < num) {
                    CFStringRef strRef = ABMultiValueCopyLabelAtIndex(propMulti, idx);
                    if (strRef) {
                        value = [NSString stringWithString:(NSString*)strRef];
                        CFRelease(strRef);
                    }
                }
                CFRelease(propMulti);
            }
        }
    }

    //Release Address Book context
    [threadAB release];

    return value;
}

- (NSArray*)getAllMultiStringValuesWithRef:(ABAddressBookRef)person property:(ABPropertyType)type {
    NSArray* values = [[[NSArray alloc] init]autorelease];

    if (person) {
        ABMultiValueRef propMulti = ABRecordCopyValue(person,type);
        if (propMulti) {
            CFArrayRef valuesRef = ABMultiValueCopyArrayOfAllValues(propMulti);
            if (valuesRef) {
                values = [[(NSArray*)valuesRef retain]autorelease];
                CFRelease(valuesRef);
            }
        }

        if (propMulti) {
            CFRelease(propMulti);
        }
    }

    return values;
}

- (NSArray*)getAllMultiStringValues:(ABRecordID)record property:(ABPropertyType)type {
    NSArray* values = [[[NSArray alloc] init]autorelease];

    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = context.abRef;

    if (record != kABRecordInvalidID) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        values = [self getAllMultiStringValuesWithRef:person property:type];
    }

    //Release Address Book context
    [context release];

    return values;
}
//
//- (CFStringRef)getABLabelFromString:(NSString *)labelStr forType:(ABPropertyID)type {
//    //TODO: do necessary conversion for labels which come from Android and other platforms.
//    return (![DataHelper isEmptyText:labelStr]) ? (CFStringRef)labelStr : kABOtherLabel;
//}

- (NSString *)getLocalizedStringFromABLabel:(NSString *)label {
    NSString *localizedStr = nil;

    CFStringRef localizedStrRef = ABAddressBookCopyLocalizedLabel((CFStringRef )label);
    if (localizedStrRef) {
        localizedStr = [[(NSString* )localizedStrRef retain] autorelease];
        CFRelease(localizedStrRef);
    } else {
        // For any case, if nil localized label is return from platform,
        // just extract readable content from the original label.
        localizedStr = [[label stringByReplacingOccurrencesOfString:@"_$!<" withString:@""] stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
    }

    return localizedStr;
}

- (NSString *)getStringValueOfRecord:(ABRecordID)record forProperty:(ABPropertyID)property {
    NSString* value = nil;

    ABContext* threadAB = [[abContexts getCurrentQueueABContext] retain];
    ABAddressBookRef ab = threadAB.abRef;

    if (record != kABRecordInvalidID) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,record);
        if (person) {
            CFStringRef str = (CFStringRef)ABRecordCopyValue(person, property);
            if (str) {
                value = (NSString* )str;
            }
        }
    }

    [threadAB release];

    return [value autorelease];
}

// A contact owns no name, no valid email or phone information, no birthday.
// is treated as empty contact.
- (BOOL)isEmptyContact:(ABRecordID)recordId {
    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
    ABAddressBookRef ab = context.abRef;
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab, recordId);

    BOOL isEmpty = YES;
    if ([self getNameOfContactWithRef:person] != nil
        || [self getNumberOfMultivaluePropsWithRef:person property:kABPersonPhoneProperty] > 0
        || [self getNumberOfMultivaluePropsWithRef:person property:kABPersonEmailProperty] > 0
        || [self getBirthDayDateOfContact:recordId] != nil) {
        isEmpty = NO;
    }

    // Release Address Book context
    [context release];

    return isEmpty;
}

//- (NSString* )getComposedVCardDataOfContact:(ABRecordID)recordID {
//    ABContext* context = [[abContexts getCurrentQueueABContext]retain];
//    ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(context.abRef, recordID);
//    CFMutableArrayRef persons = (CFMutableArrayRef)[NSMutableArray arrayWithCapacity:1];
//    CFArrayAppendValue(persons, abPerson);
//    NSData* composedVcardData = (NSData* )ABPersonCreateVCardRepresentationWithPeople(persons);
//    [context release];
//    return [[[NSString alloc] initWithData:[composedVcardData autorelease]
//                                 encoding:NSUTF8StringEncoding] autorelease];
//}
//
//- (NSUInteger)maxSupportEmailCountForPerson:(ABRecordRef)person {
//    ABRecordRef source = ABPersonCopySource(person);
//    CFTypeRef sourceType = ABRecordCopyValue(source, kABSourceTypeProperty);
//
//    // No limitation to local source person, and 3 to other sources.
//    NSUInteger maxCount = (kABSourceTypeLocal == [(NSNumber *)sourceType intValue]) ? UINT32_MAX : 3;
//
//    CFRelease(sourceType);
//    CFRelease(source);
//
//    return maxCount;
//}
@end

/** @} */
