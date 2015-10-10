@import CoreData;

typedef NS_OPTIONS(NSUInteger, DATAFilterChangOperations) {
    DATAFilterChangOperationInsert = 1 << 0,
    DATAFilterChangOperationUpdate = 1 << 1,
    DATAFilterChangOperationDelete = 1 << 2,
    DATAFilterChangOperationAll = 0xFFFFFFFF
};

@interface DATAFilter : NSObject

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
       localKey:(NSString *)localKey
      remoteKey:(NSString *)remoteKey
        context:(NSManagedObjectContext *)context
       inserted:(void (^)(NSDictionary *objectJSON))inserted
        updated:(void (^)(NSDictionary *objectJSON, NSManagedObject *updatedObject))updated;

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
       localKey:(NSString *)localKey
      remoteKey:(NSString *)remoteKey
        context:(NSManagedObjectContext *)context
      predicate:(NSPredicate *)predicate
       inserted:(void (^)(NSDictionary *objectJSON))inserted
        updated:(void (^)(NSDictionary *objectJSON, NSManagedObject *updatedObject))updated;


+ (void)changes:(NSArray *)changes
     operations:(DATAFilterChangOperations)operations
  inEntityNamed:(NSString *)entityName
       localKey:(NSString *)localKey
      remoteKey:(NSString *)remoteKey
        context:(NSManagedObjectContext *)context
       inserted:(void (^)(NSDictionary *objectJSON))inserted
        updated:(void (^)(NSDictionary *objectJSON, NSManagedObject *updatedObject))updated;

+ (void)changes:(NSArray *)changes
     operations:(DATAFilterChangOperations)operations
  inEntityNamed:(NSString *)entityName
       localKey:(NSString *)localKey
      remoteKey:(NSString *)remoteKey
        context:(NSManagedObjectContext *)context
      predicate:(NSPredicate *)predicate
       inserted:(void (^)(NSDictionary *objectJSON))inserted
        updated:(void (^)(NSDictionary *objectJSON, NSManagedObject *updatedObject))updated;

@end
