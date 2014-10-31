//
//  NSManagedObject+ANDYMapChanges.m
//
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

#import "NSManagedObject+ANDYMapChanges.h"

@implementation NSManagedObject (ANDYMapChangesPrivate)

+ (NSMutableDictionary *)dictionaryOfIDsAndFetchedIDsInContext:(NSManagedObjectContext *)context
                                                 usingLocalKey:(NSString *)localKey
                                                 forEntityName:(NSString *)entityName
{
    return [self dictionaryOfIDsAndFetchedIDsUsingPredicate:nil
                                                andLocalKey:localKey
                                                  inContext:context
                                              forEntityName:entityName];
}

+ (NSMutableDictionary *)dictionaryOfIDsAndFetchedIDsUsingPredicate:(NSPredicate *)predicate
                                                        andLocalKey:(NSString *)localKey
                                                          inContext:(NSManagedObjectContext *)context
                                                      forEntityName:(NSString *)entityName
{
    __block NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [context performBlockAndWait:^{
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
        fetchRequest.predicate = predicate;
        [fetchRequest setResultType:NSDictionaryResultType];
        NSExpressionDescription *objectIdDesc = [[NSExpressionDescription alloc] init];
        objectIdDesc.name = @"objectID";
        objectIdDesc.expression = [NSExpression expressionForEvaluatedObject];
        objectIdDesc.expressionResultType = NSObjectIDAttributeType;
        [fetchRequest setPropertiesToFetch:@[objectIdDesc, localKey]];

        NSArray *objects = [context executeFetchRequest:fetchRequest error:&error];
        for (NSDictionary *object in objects) {
            NSNumber *fetchedID = [object valueForKeyPath:localKey];
            if (fetchedID) {
                [dictionary setObject:[object valueForKeyPath:@"objectID"] forKey:fetchedID];
            }
        }
    }];

    return dictionary;
}

@end

@implementation NSManagedObject (ANDYMapChanges)

+ (void)andy_mapChanges:(NSArray *)changes
              inContext:(NSManagedObjectContext *)context
          forEntityName:(NSString *)entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated
{
    [self andy_mapChanges:changes
                 localKey:@"id"
                remoteKey:@"id"
           usingPredicate:nil
                inContext:context
            forEntityName:entityName
                 inserted:inserted
                  updated:updated];
}

+ (void)andy_mapChanges:(NSArray *)changes
               localKey:(NSString *)localKey
              remoteKey:(NSString *)remoteKey
         usingPredicate:(NSPredicate *)predicate
              inContext:(NSManagedObjectContext *)context
          forEntityName:(NSString *)entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated
{
    NSMutableDictionary *dictionaryIDAndObjectID = nil;

    if (predicate) {
        dictionaryIDAndObjectID = [self dictionaryOfIDsAndFetchedIDsUsingPredicate:predicate
                                                                       andLocalKey:localKey
                                                                         inContext:context
                                                                     forEntityName:entityName];
    } else {
        dictionaryIDAndObjectID = [self dictionaryOfIDsAndFetchedIDsInContext:context
                                                                usingLocalKey:localKey
                                                                forEntityName:entityName];
    }

    NSArray *fetchedObjectIDs = [dictionaryIDAndObjectID allKeys];
    NSArray *remoteObjectIDs = [changes valueForKey:remoteKey];

    NSMutableSet *intersection = [NSMutableSet setWithArray:remoteObjectIDs];
    [intersection intersectSet:[NSSet setWithArray:fetchedObjectIDs]];
    NSArray *updatedObjectIDs = [intersection allObjects];

    NSMutableArray *deletedObjectIDs = [NSMutableArray arrayWithArray:fetchedObjectIDs];
    [deletedObjectIDs removeObjectsInArray:remoteObjectIDs];

    NSMutableArray *insertedObjectIDs = [NSMutableArray arrayWithArray:remoteObjectIDs];
    [insertedObjectIDs removeObjectsInArray:fetchedObjectIDs];

    for (NSNumber *fetchedID in deletedObjectIDs) {
        NSManagedObjectID *objectID = [dictionaryIDAndObjectID objectForKey:fetchedID];
        if (objectID) {
            NSManagedObject *object = [context objectWithID:objectID];
            if (object) {
                [context deleteObject:object];
            }
        }
    }

    for (NSNumber *fetchedID in insertedObjectIDs) {
        [changes enumerateObjectsUsingBlock:^(NSDictionary *objectDict, NSUInteger idx, BOOL *stop) {
            if ([[objectDict objectForKey:remoteKey] isEqual:fetchedID]) {
                if (inserted) {
                    inserted(objectDict);
                }
            }
        }];
    }

    for (NSNumber *fetchedID in updatedObjectIDs) {
        [changes enumerateObjectsUsingBlock:^(NSDictionary *objectDict, NSUInteger idx, BOOL *stop) {
            if ([[objectDict objectForKey:remoteKey] isEqual:fetchedID]) {
                NSManagedObjectID *objectID = [dictionaryIDAndObjectID objectForKey:fetchedID];
                if (objectID) {
                    NSManagedObject *object = [context objectWithID:objectID];
                    if (object && updated) {
                        updated(objectDict, object);
                    }
                }
            }
        }];
    }
}

@end
