//
//  CoreDataManager.h
//  avatarSyncor
//
//  Created by Jerry Lee on 8/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataManager : NSObject<NSFetchedResultsControllerDelegate>

+ (CoreDataManager*) sharedManager;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/**
 @brief Forces a save main context. Used to save in case of failures, errors, or app terminated
 */
- (void)saveMainContextChanges;

/**
 @brief Helper method to fetch all entities with predicate and sorting
 
 Provides a wrapper around NSFetchRequest. It basically makes the same as creating a Fetch request manually.
 
 @param entity the Entity name to target the fetch
 @param predicate The created predicate to use in the fetch. Use nil if you don't want to specify it.
 @param sort SortDescriptor to use in the fetch. Use nil if you don't want to specify it.
 @param limitnum Number of entities to fetch. Use 0 not to limit the fetch to any number explicitly.
 */
- (NSArray*)fetchAllEntities:(NSString*)entity 
               withPredicate:(NSPredicate*)predicate 
                 withSorting:(NSSortDescriptor*)sort 
                  fetchLimit:(NSUInteger)limitnum
           prefetchRelations:(NSArray*)prefetchRelations
                     context:(NSManagedObjectContext *)context;

/**
 @brief Helper method to fetch an identity with a given predicate. Useful for simple fetchs of single entities
 */
- (NSManagedObject*)fetchEntity:(NSString*)entity
                  withPredicate:(NSPredicate*)predicate
              prefetchRelations:(NSArray*) prefetchRelations context:(NSManagedObjectContext *)context;

@end
