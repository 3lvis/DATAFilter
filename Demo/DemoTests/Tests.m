@import XCTest;

#import "DATAFilter.h"

#import "DATAObjectIDs.h"

#import "DATAStack.h"

@interface DemoTests : XCTestCase

@end

@implementation DemoTests

- (NSManagedObject *)userWithID:(NSInteger)remoteID
                      firstName:(NSString *)firstName
                       lastName:(NSString *)lastName
                            age:(NSInteger)age
                      inContext:(NSManagedObjectContext *)context {
    NSManagedObject *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                          inManagedObjectContext:context];

    [user setValue:@(remoteID) forKey:@"remoteID"];
    [user setValue:firstName forKey:@"firstName"];
    [user setValue:lastName forKey:@"lastName"];
    [user setValue:@(age) forKey:@"age"];

    [context save:nil];

    return user;
}

- (NSManagedObject *)noteWithID:(NSString *)remoteID
                           note:(NSString *)text
                      inContext:(NSManagedObjectContext *)context {
    NSManagedObject *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note"
                                                          inManagedObjectContext:context];

    [note setValue:remoteID forKey:@"remoteID"];
    [note setValue:text forKey:@"note"];

    [context save:nil];

    return note;
}

- (id)JSONObjectWithContentsOfFile:(NSString*)fileName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *filePath = [bundle pathForResource:[fileName stringByDeletingPathExtension]
                                          ofType:[fileName pathExtension]];

    NSData *data = [NSData dataWithContentsOfFile:filePath];

    NSError *error = nil;

    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingMutableContainers
                                                  error:&error];
    if (error != nil) return nil;

    return result;
}

- (void)createUsersInContext:(NSManagedObjectContext *)context {
    [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:context];
    [self userWithID:1 firstName:@"Ben" lastName:@"Boykewich" age:23 inContext:context];
    [self userWithID:2 firstName:@"Ricky" lastName:@"Underwood" age:19 inContext:context];
    [self userWithID:3 firstName:@"Grace" lastName:@"Bowman" age:20 inContext:context];
    [self userWithID:4 firstName:@"Adrian" lastName:@"Lee" age:20 inContext:context];
}

- (void)testUsersCount {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];
    NSManagedObjectContext *context = stack.mainContext;

    [self createUsersInContext:context];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    NSInteger count = [context countForFetchRequest:request error:nil];

    XCTAssertEqual(count, 5);
}

- (void)testMapChangesA {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];

        NSDictionary *before = [DATAObjectIDs objectIDsInEntityNamed:@"User"
                                                 withAttributesNamed:@"remoteID"
                                                             context:context];
        id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

        __block NSInteger inserted = 0;
        __block NSInteger updated = 0;
        __block NSInteger deleted = before.count;

        [DATAFilter changes:JSON
              inEntityNamed:@"User"
                   localKey:@"remoteID"
                  remoteKey:@"id"
                    context:context
                  predicate:nil
                   inserted:^(NSDictionary *objectJSON) {
                       inserted++;
                   } updated:^(NSDictionary *objectJSON, NSManagedObject *updatedObject) {
                       updated++;
                       deleted--;
                   }];

        XCTAssertEqual(inserted, 2);
        XCTAssertEqual(updated, 4);
        XCTAssertEqual(deleted, 1);
    }];
}

- (void)testMapChangesB {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];

        NSDictionary *before = [DATAObjectIDs objectIDsInEntityNamed:@"User"
                                                 withAttributesNamed:@"remoteID"
                                                             context:context];
        id JSON = [self JSONObjectWithContentsOfFile:@"users2.json"];

        __block NSInteger inserted = 0;
        __block NSInteger updated = 0;
        __block NSInteger deleted = before.count;

        [DATAFilter changes:JSON
              inEntityNamed:@"User"
                   localKey:@"remoteID"
                  remoteKey:@"id"
                    context:context
                  predicate:nil
                   inserted:^(NSDictionary *objectJSON) {
                       inserted++;
                   } updated:^(NSDictionary *objectJSON, NSManagedObject *updatedObject) {
                       updated++;
                       deleted--;
                   }];

        XCTAssertEqual(inserted, 0);
        XCTAssertEqual(updated, 5);
        XCTAssertEqual(deleted, 0);
    }];
}

- (void)testMapChangesC {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];
        NSDictionary *before = [DATAObjectIDs objectIDsInEntityNamed:@"User"
                                                 withAttributesNamed:@"remoteID"
                                                             context:context];

        id JSON = [self JSONObjectWithContentsOfFile:@"users3.json"];

        __block NSInteger inserted = 0;
        __block NSInteger updated = 0;
        __block NSInteger deleted = before.count;

        [DATAFilter changes:JSON
              inEntityNamed:@"User"
                   localKey:@"remoteID"
                  remoteKey:@"id"
                    context:context
                  predicate:nil
                   inserted:^(NSDictionary *objectJSON) {
                       inserted++;
                   } updated:^(NSDictionary *objectJSON, NSManagedObject *updatedObject) {
                       updated++;
                       deleted--;
                   }];

        XCTAssertEqual(inserted, 0);
        XCTAssertEqual(updated, 0);
        XCTAssertEqual(deleted, 5);
    }];
}

- (void)testUniquing {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];

        [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:context];
        [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:context];
        [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:context];
        [context save:nil];

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        NSInteger numberOfUsers = [context countForFetchRequest:request error:nil];
        XCTAssertEqual(numberOfUsers, 8);

        id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

        [DATAFilter changes:JSON
              inEntityNamed:@"User"
                   localKey:@"remoteID"
                  remoteKey:@"id"
                    context:context
                  predicate:nil
                   inserted:nil
                    updated:nil];

        NSInteger deletedNumberOfUsers = [context countForFetchRequest:request error:nil];
        XCTAssertEqual(deletedNumberOfUsers, 4);
    }];
}

- (void)testStringID {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        [self noteWithID:@"123" note:@"text" inContext:context];
        [context save:nil];

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
        NSInteger numberOfUsers = [context countForFetchRequest:request error:nil];
        XCTAssertEqual(numberOfUsers, 1);

        id JSON = [self JSONObjectWithContentsOfFile:@"note.json"];

        [DATAFilter changes:JSON
              inEntityNamed:@"Note"
                   localKey:@"remoteID"
                  remoteKey:@"id"
                    context:context
                  predicate:nil
                   inserted:^(NSDictionary *objectJSON) {
                       XCTAssertFalse(true, @"shoudn't create an object");
                   } updated:^(NSDictionary *objectJSON, NSManagedObject *updatedObject) {
                       XCTAssertEqualObjects(objectJSON[@"id"], @"123");
                   }];
    }];
}

- (void)testDuplicatedItems {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        NSDictionary *before = [DATAObjectIDs objectIDsInEntityNamed:@"User"
                                                 withAttributesNamed:@"remoteID"
                                                             context:context];
        id JSON = [self JSONObjectWithContentsOfFile:@"duplicated.json"];

        __block NSInteger inserted = 0;
        __block NSInteger updated = 0;
        __block NSInteger deleted = before.count;

        [DATAFilter changes:JSON
              inEntityNamed:@"User"
                   localKey:@"remoteID"
                  remoteKey:@"id"
                    context:context
                  predicate:nil
                   inserted:^(NSDictionary *objectJSON) {
                       inserted++;
                   } updated:^(NSDictionary *objectJSON, NSManagedObject *updatedObject) {
                       updated++;
                       deleted--;
                   }];

        XCTAssertEqual(inserted, 2);
        XCTAssertEqual(updated, 0);
        XCTAssertEqual(deleted, 0);
    }];
}

@end
