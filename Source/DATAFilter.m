#import "DATAFilter.h"

#import "DATAObjectIDs.h"

@implementation DATAFilter

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
       localKey:(NSString *)localKey
      remoteKey:(NSString *)remoteKey
        context:(NSManagedObjectContext *)context
       inserted:(void (^)(NSDictionary *objectJSON))inserted
        updated:(void (^)(NSDictionary *objectJSON, NSManagedObject *updatedObject))updated
{
    return [self changes:changes
              operations:DATAFilterChangOperationAll
           inEntityNamed:entityName
                localKey:localKey
               remoteKey:remoteKey
                 context:context
               predicate:nil
                inserted:inserted
                 updated:updated];
}

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
       localKey:(NSString *)localKey
      remoteKey:(NSString *)remoteKey
        context:(NSManagedObjectContext *)context
      predicate:(NSPredicate *)predicate
       inserted:(void (^)(NSDictionary *objectJSON))inserted
        updated:(void (^)(NSDictionary *objectJSON, NSManagedObject *updatedObject))updated
{
    return [self changes:changes
              operations:DATAFilterChangOperationAll
           inEntityNamed:entityName
                localKey:localKey
               remoteKey:remoteKey
                 context:context
               predicate:predicate
                inserted:inserted
                 updated:updated];
}



+ (void)changes:(NSArray *)changes
     operations:(DATAFilterChangOperations)operations
  inEntityNamed:(NSString *)entityName
       localKey:(NSString *)localKey
      remoteKey:(NSString *)remoteKey
        context:(NSManagedObjectContext *)context
       inserted:(void (^)(NSDictionary *objectJSON))inserted
        updated:(void (^)(NSDictionary *objectJSON, NSManagedObject *updatedObject))updated {
    return [self changes:changes
              operations:operations
           inEntityNamed:entityName
                localKey:localKey
               remoteKey:remoteKey
                 context:context
               predicate:nil
                inserted:inserted
                 updated:updated];
}

+ (void)changes:(NSArray *)changes
     operations:(DATAFilterChangOperations)operations
  inEntityNamed:(NSString *)entityName
       localKey:(NSString *)localKey
      remoteKey:(NSString *)remoteKey
        context:(NSManagedObjectContext *)context
      predicate:(NSPredicate *)predicate
       inserted:(void (^)(NSDictionary *objectJSON))inserted
        updated:(void (^)(NSDictionary *objectJSON, NSManagedObject *updatedObject))updated {
    NSDictionary *dictionaryIDAndObjectID = [DATAObjectIDs objectIDsInEntityNamed:entityName
                                                              withAttributesNamed:localKey
                                                                          context:context
                                                                        predicate:predicate];

    NSArray *fetchedObjectIDs = [dictionaryIDAndObjectID allKeys];
    NSMutableArray *remoteObjectIDs = [[changes valueForKey:remoteKey] mutableCopy];
    [remoteObjectIDs removeObject:[NSNull null]];

    NSDictionary *remoteIDAndChange = [NSDictionary dictionaryWithObjects:changes
                                                                  forKeys:remoteObjectIDs];

    NSMutableSet *intersection = [NSMutableSet setWithArray:remoteObjectIDs];
    [intersection intersectSet:[NSSet setWithArray:fetchedObjectIDs]];
    NSArray *updatedObjectIDs = intersection.allObjects;

    NSMutableArray *deletedObjectIDs = [fetchedObjectIDs mutableCopy];
    [deletedObjectIDs removeObjectsInArray:remoteObjectIDs];

    NSMutableArray *insertedObjectIDs = [remoteObjectIDs mutableCopy];
    [insertedObjectIDs removeObjectsInArray:fetchedObjectIDs];

    if (operations & DATAFilterChangOperationDelete){
        for (id fetchedID in deletedObjectIDs) {
            NSManagedObjectID *objectID = dictionaryIDAndObjectID[fetchedID];
            if (objectID) {
                NSManagedObject *object = [context objectWithID:objectID];
                if (object) {
                    [context deleteObject:object];
                }
            }
        }
    }

    if (operations & DATAFilterChangOperationInsert){
        for (id fetchedID in insertedObjectIDs) {
            NSDictionary *objectDictionary = remoteIDAndChange[fetchedID];
            if (inserted) {
                inserted(objectDictionary);
            }
        }
    }

    if (operations & DATAFilterChangOperationUpdate){
        for (id fetchedID in updatedObjectIDs) {
            NSDictionary *objectDictionary = remoteIDAndChange[fetchedID];
            NSManagedObjectID *objectID = dictionaryIDAndObjectID[fetchedID];
            if (objectID) {
                NSManagedObject *object = [context objectWithID:objectID];
                if (object && updated) {
                    updated(objectDictionary, object);
                }
            }
        }
    }
}

@end
