@import XCTest;

#import "NSManagedObject+ANDYMapChanges.h"

#import "NSManagedObject+ANDYObjectIDs.h"

#import "DATAStack.h"

@interface DemoTests : XCTestCase

@end

@implementation DemoTests

- (NSManagedObject *)userWithID:(NSInteger)remoteID
                      firstName:(NSString *)firstName
                       lastName:(NSString *)lastName
                            age:(NSInteger)age
                      inContext:(NSManagedObjectContext *)context
{
    NSManagedObject *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                          inManagedObjectContext:context];

    [user setValue:@(remoteID) forKey:@"remoteID"];
    [user setValue:firstName forKey:@"firstName"];
    [user setValue:lastName forKey:@"lastName"];
    [user setValue:@(age) forKey:@"age"];

    [context save:nil];

    return user;
}

- (id)JSONObjectWithContentsOfFile:(NSString*)fileName
{
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

- (void)createUsersInContext:(NSManagedObjectContext *)context
{
    [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:context];
    [self userWithID:1 firstName:@"Ben" lastName:@"Boykewich" age:23 inContext:context];
    [self userWithID:2 firstName:@"Ricky" lastName:@"Underwood" age:19 inContext:context];
    [self userWithID:3 firstName:@"Grace" lastName:@"Bowman" age:20 inContext:context];
    [self userWithID:4 firstName:@"Adrian" lastName:@"Lee" age:20 inContext:context];
}

- (void)testUsersCount
{
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];
    NSManagedObjectContext *context = stack.mainThreadContext;

    [self createUsersInContext:context];

    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    NSInteger count = [context countForFetchRequest:request error:&error];

    XCTAssertEqual(count, 5);
}

- (void)testMapChangesWithExplicitKeys
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundThreadContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];

        NSDictionary *before = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:context
                                                                             usingLocalKey:@"remoteID"
                                                                             forEntityName:@"User"];

        id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

        __block NSInteger inserted = 0;
        __block NSInteger updated = 0;
        __block NSInteger deleted = before.count;

        [NSManagedObject andy_mapChanges:JSON
                                localKey:@"remoteID"
                               remoteKey:@"id"
                          usingPredicate:nil
                               inContext:context
                           forEntityName:@"User"
                                inserted:^(NSDictionary *objectDict) {
                                    inserted++;
                                } updated:^(NSDictionary *objectDict, NSManagedObject *object) {
                                    updated++;
                                    deleted--;
                                }];

        XCTAssertEqual(inserted, 2);
        XCTAssertEqual(updated, 4);
        XCTAssertEqual(deleted, 1);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testMapChangesWithInferredKeys
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundThreadContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];

        NSDictionary *before = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:context
                                                                             usingLocalKey:@"remoteID"
                                                                             forEntityName:@"User"];

        id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

        __block NSInteger inserted = 0;
        __block NSInteger updated = 0;
        __block NSInteger deleted = before.count;

        [NSManagedObject andy_mapChanges:JSON
                          usingPredicate:nil
                               inContext:context
                           forEntityName:@"User"
                                inserted:^(NSDictionary *objectDict) {
                                    inserted++;
                                } updated:^(NSDictionary *objectDict, NSManagedObject *object) {
                                    updated++;
                                    deleted--;
                                }];

        XCTAssertEqual(inserted, 2);
        XCTAssertEqual(updated, 4);
        XCTAssertEqual(deleted, 1);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testMapChangesB
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundThreadContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];

        NSDictionary *before = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:context
                                                                             usingLocalKey:@"remoteID"
                                                                             forEntityName:@"User"];

        id JSON = [self JSONObjectWithContentsOfFile:@"users2.json"];

        __block NSInteger inserted = 0;
        __block NSInteger updated = 0;
        __block NSInteger deleted = before.count;

        [NSManagedObject andy_mapChanges:JSON
                                localKey:@"remoteID"
                               remoteKey:@"id"
                          usingPredicate:nil
                               inContext:context
                           forEntityName:@"User"
                                inserted:^(NSDictionary *objectDict) {
                                    inserted++;
                                } updated:^(NSDictionary *objectDict, NSManagedObject *object) {
                                    updated++;
                                    deleted--;
                                }];

        XCTAssertEqual(inserted, 0);
        XCTAssertEqual(updated, 5);
        XCTAssertEqual(deleted, 0);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testMapChangesC
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundThreadContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];

        NSDictionary *before = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:context
                                                                             usingLocalKey:@"remoteID"
                                                                             forEntityName:@"User"];

        id JSON = [self JSONObjectWithContentsOfFile:@"users3.json"];

        __block NSInteger inserted = 0;
        __block NSInteger updated = 0;
        __block NSInteger deleted = before.count;

        [NSManagedObject andy_mapChanges:JSON
                                localKey:@"remoteID"
                               remoteKey:@"id"
                          usingPredicate:nil
                               inContext:context
                           forEntityName:@"User"
                                inserted:^(NSDictionary *objectDict) {
                                    inserted++;
                                } updated:^(NSDictionary *objectDict, NSManagedObject *object) {
                                    updated++;
                                    deleted--;
                                }];

        XCTAssertEqual(inserted, 0);
        XCTAssertEqual(updated, 0);
        XCTAssertEqual(deleted, 5);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testUniquing
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundThreadContext:^(NSManagedObjectContext *context) {
        [self createUsersInContext:context];

        [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:context];
        [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:context];
        [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:context];
        [context save:nil];

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        NSInteger numberOfUsers = [context countForFetchRequest:request error:nil];
        XCTAssertEqual(numberOfUsers, 8);

        id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

        [NSManagedObject andy_mapChanges:JSON
                          usingPredicate:nil
                               inContext:context
                           forEntityName:@"User"
                                inserted:nil
                                 updated:nil];

        NSInteger deletedNumberOfUsers = [context countForFetchRequest:request error:nil];
        XCTAssertEqual(deletedNumberOfUsers, 4);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
