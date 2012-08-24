//
//  CoreDataManager.m
//  avatarSyncor
//
//  Created by Jerry Lee on 8/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CoreDataManager.h"

static CoreDataManager *sharedInstance;

@implementation CoreDataManager

@synthesize managedObjectContext = _managedObjectContext;


+ (CoreDataManager*) sharedManager {
    @synchronized([CoreDataManager class]) {
        if (!sharedInstance) {
            sharedInstance = [[CoreDataManager alloc] init];
        }
    }
    return sharedInstance;
}

// NOTE: NEVER call it within the finishblock of saveUsingBackgroundContextWithBlock, it will lead to deadlock
- (void)saveMainContextChanges {
    if ([_managedObjectContext hasChanges]) {
        NSError* error = nil;
        if(![_managedObjectContext save:&error]){
            NSLog(@"*****Unresolved error saving main context%@, %@*****", error, [error userInfo]);
        }
    }
}

- (NSArray*)fetchAllEntities:(NSString*)entity
               withPredicate:(NSPredicate*)predicate
                 withSorting:(NSSortDescriptor*)sort
                  fetchLimit:(NSUInteger)limitnum
           prefetchRelations:(NSArray*) prefetchRelations
                     context:(NSManagedObjectContext *)context{
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName: entity];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = limitnum;
    if (prefetchRelations) {
        [fetchRequest setRelationshipKeyPathsForPrefetching:prefetchRelations];
    }
    
    if (sort) {
        fetchRequest.sortDescriptors = [NSArray arrayWithObject:sort];
    }
    
    NSArray*  fetched = [(context ? context : self.managedObjectContext) executeFetchRequest: fetchRequest error: &error] ;
    if (error) {
        NSLog(@"Error reading Core Data %@",error);
        fetched = nil;
    }
    
    return fetched;
}

- (NSManagedObject*)fetchEntity:(NSString*)entity withPredicate:(NSPredicate*)predicate prefetchRelations:(NSArray*) prefetchRelations context:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName: entity];
    NSError *error = nil;
    fetchRequest.predicate = predicate;
    if (prefetchRelations) {
        [fetchRequest setRelationshipKeyPathsForPrefetching:prefetchRelations];
    }
    NSArray *contactFetchResult = [(context ? context : self.managedObjectContext) executeFetchRequest: fetchRequest error: &error];
    
    if (error) {
        NSLog(@"Error reading Core Data %@",error);
    }
    
    NSManagedObject* fetched = nil;
    if (!error && [contactFetchResult count] > 0) {
        fetched = (NSManagedObject*)[contactFetchResult objectAtIndex:0];
    }
    return fetched;
}

@end
