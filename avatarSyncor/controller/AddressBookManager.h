/** \addtogroup CONTROLLER
 *  @{
 */

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class ABContextPool;

@protocol AddressBookManagerDelegate <NSObject>

- (void)addressBookDidChanged;

@end

/**
 @brief This class interfaces with iOS system address book, reads contacts and returns desired information about specific
 record IDs. From outside this class only ABRecordIds (NSNumber in an NSArray) can be accessed
 */
@interface AddressBookManager : NSObject 


@property (nonatomic, assign) id<AddressBookManagerDelegate> delegate;

/**
 @brief Keys of native address book labels,
 which provide convenience on UI display, storage, multiple language support, etc.
 The order of the contents in the array is meaningful.
 */
@property (nonatomic,readonly) NSArray *abPhoneLabels;
@property (nonatomic,readonly) NSArray *abEmailLabels;

/**
 @brief Executes a fetch in backcround to get all address book record ids
 */
- (NSArray*)getAllABRecordIds;

/**
 @brief Queries, without fetching, if contact has image related to it
 @param record to fetch data from
 @retun YES if addressbook has a contact image for this record, NO otherwise
 */
- (BOOL)hasContactAvatar:(ABRecordID)record;

/**
 @brief Gets the image of contact with thumbnail size, if available 
 @param record to fetch data from
 @return avatar image with thumbnail size existing in the db
 */
- (UIImage *)getAvatarOfContact:(ABRecordID)record;

/**
 @brief Gets the image of contact with original size, if available 
 @param record to fetch data from
 @return avatar image with original size existing in the db
 */
- (UIImage *)getFullSizeAvatarOfContact:(ABRecordID)record;

/**
 @brief Gets a combined name for the contact with available names data
 @param record to fetch data from
 @return combined string with name (firstname, lastname, etc) from contact
 */
- (NSString *)getNameOfContact:(ABRecordID)record;

/**
 @brief Gets the birthday date, if available from the contact
 @param record to fetch data from
 @return the date or nil if it doesn't exist
 */
- (NSDate*)getBirthDayDateOfContact:(ABRecordID)record;

/**
 @brief Get the Family Name of a  Contact.
 @param record(ABRecordID) an Identifier uniquely identify the record associated with the contact in the addressbook
 @return Firstname(NSString*) of the contact or nil if not exist.
 */
- (NSString* )getFamilyNameOfContact:(ABRecordID)record;

/**
 @brief Get the Given Name of a  Contact.
 @param record(ABRecordID) an Identifier uniquely identify the record associated with the contact in the addressbook
 @return Lastname(NSString*) of the contact or nil if not exist.
 */
- (NSString* )getGivenNameOfContact:(ABRecordID)record;

/**
 @brief Get the FamilyNamePhonetic of a Contact.
 @param record(ABRecordID) an Identifier uniquely identify the record associated with the contact in the addressbook
 @return FirstNamePhonetic(NSString*) of the contact or nil if not exist.
 */
- (NSString* )getPhoneticFamilyNameOfContact:(ABRecordID)record;

/**
 @brief Get the GivenNamePhonetic of a Contact.
 @param record(ABRecordID) an Identifier uniquely identify the record associated with the contact in the addressbook
 @return LastNamePhonetic(NSString*) of the contact or nil if not exist.
 */
- (NSString* )getPhoneticGivenNameOfContact:(ABRecordID)record;

/**
 @brief Gets number of telephone number fields available for the contact
 @param record to fetch data from
 @return the number of available tn fields
 */
- (int)getNumberofTNFieldsOfContact:(ABRecordID)record;

/**
 @brief Gets telephone number at index, if exists
 @param record to fetch data from
 @return tel number or nil if it doesn't exist
 */
- (NSString*)getTnForContact:(ABRecordID)record atIndex:(int)idx;

/**
 @brief Gets all telephone numbers available for the contact
 @param record to fetch data from
 @return Array filled with NSString containing the available tn fields. Empty array if none available
 */
- (NSArray*)getAllTnForContact:(ABRecordID)record;

/**
 @brief Gets number ofemail fields available for the contact
 @param record to fetch data from
 @return the number of available email fields
 */
- (int)getNumberofEmailsOfContact:(ABRecordID)record;

/**
 @brief Gets email at index, if exists
 @param record to fetch data from
 @param idx of email address
 @return email or nil if it doesn't exist
 */
- (NSString *)getEmailForContact:(ABRecordID)record atIndex:(int)idx;

/**
 @brief Gets email label at index, if exists
 @param record to fetch data from
 @param idx label of email address
 @return email label or nil if it doesn't exist
 */
- (NSString *)getEmailLabelForContact:(ABRecordID)record atIndex:(int)idx;

/**
 @brief Gets phone number at index, if exists
 @param record to fetch data from
 @param idx of phone number
 @return phone number label or nil if it doesn't exist
 */
- (NSString *)getPhoneForContact:(ABRecordID)record atIndex:(int)idx;

/**
 @brief Gets phone number label at index, if exists
 @param record to fetch data from
 @param idx of phone number
 @return phone number label or nil if it doesn't exist
 */
- (NSString *)getPhoneLabelForContact:(ABRecordID)record atIndex:(int)idx;

/**
 @brief Returns a localized version of a record-property label string.
 @param label The label to localize.
 @return Localized string for the label.
 */
- (NSString *)getLocalizedStringFromABLabel:(NSString *)label;

/**
 @brief Gets dictionary of emails and it's labels
 @param record to fetch data from
 @return dictionary of email addresses or nil
 */
//- (NSDictionary *)getEmailsDictionaryForRecordId:(ABRecordID)recordId;

/**
 @brief Gets dictionary of phone numbers and it's labels
 @param record to fetch data from
 @return dictionary of phone numbers or nil
 */
//- (NSDictionary *)getPhoneNumbersDictionaryForRecordId:(ABRecordID)recordId;

/**
 @brief Gets all phone available for the contact
 @param record to fetch data from
 @return Array filled with NSString containing the available phone fields. Empty array if none available
 */
- (NSArray*)getAllTnForContact:(ABRecordID)record;

/**
 @brief Gets all email available for the contact
 @param record to fetch data from
 @return Array filled with NSString containing the available email fields. Empty array if none available
 */
- (NSArray *)getAllEmailForContact:(ABRecordID)record;

/**
 @brief Gets update date of contact
 @param record contact record id
 @return update date
 */
- (NSDate *)getUpdateDateForContact:(ABRecordID)record;

///**
// @brief Add new contact with given stuff
// @param avatar nil to ingore it. NSNull denote to set it as nil.
// @return new contact's nabId
// */
//- (ABRecordID)addContactToAddressBookWithPhones:(NSArray *)phones
//                          withPhoneLabels:(NSArray *)phoneLabels
//                               withEmails:(NSArray *)emails
//                          withEmailLabels:(NSArray *)emailLabels
//                               withAvatar:(id)avatar
//                             withBirthday:(NSString *)birthday
//                           withFamilyName:(NSString *)familyName
//                            withGivenName:(NSString *)givenName
//                   withPhoneticFamilyName:(NSString *)phoneticFamilyName
//                    withPhoneticGivenName:(NSString *)phoneticGivenName;



/**
 @brief Update contact with avatar image, we allow data is null which denote remove the avatar from native address.
 @param ABRecordID contact record, avImageData avatar image data
 */
- (void)updateABRecord:(ABRecordID)record withAvatarData:(NSData *)data;

///**
// @brief Merge contact identity (local contact) with contact dictionary from server or
//        updates from local editing.
// @param nabId of contact
// @param avatar nil to ingore it. NSNull denote to set it as nil.
// @param overwrite indicates if contact should be overwrite.
// @return YES if there has been any merge done to the contact
// */
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
//           overwrite:(BOOL)overwrite;

/**
 @brief delete one addressbook record from address database.
 @param record contact record id
 */
-(void)deleteABRecord:(ABRecordID)record;

/**
 Current list of recordIds from AddressBook
 */
@property (nonatomic, readonly) NSArray* sharedPeopleArray;

///**
// @brief Get Composed vCard data of the address book person
// @param recordID ABRecordID contact record id associated with the address book person
// @return NSString* the Composed vCard data
// */
//- (NSString* )getComposedVCardDataOfContact:(ABRecordID)recordID;

@end

/** @} */