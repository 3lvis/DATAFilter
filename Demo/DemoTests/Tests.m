//
//  DemoTests.m
//  DemoTests
//
//  Created by Elvis Nunez on 10/29/14.
//  Copyright (c) 2014 ANDY. All rights reserved.
//

@import XCTest;

#import "NSManagedObject+ANDYMapChanges.h"

@interface DemoTests : XCTestCase

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation DemoTests

#pragma mark - Set up

- (NSManagedObjectContext *)context
{
    if (_context) return _context;

    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSInMemoryStoreType
                                                 configuration:nil
                                                           URL:nil
                                                       options:nil
                                                         error:nil];
    NSAssert(store, @"Should have a store by now");

    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _context.persistentStoreCoordinator = psc;

    return _context;
}

- (NSManagedObject *)userWithID:(NSInteger)userID
                      firstName:(NSString *)firstName
                       lastName:(NSString *)lastName
                            age:(NSInteger)age
                      inContext:(NSManagedObjectContext *)context
{
    NSManagedObject *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                          inManagedObjectContext:context];

    [user setValue:@(userID) forKey:@"userID"];
    [user setValue:firstName forKey:@"firstName"];
    [user setValue:lastName forKey:@"lastName"];
    [user setValue:@(age) forKey:@"age"];

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

- (void)setUp
{
    [super setUp];

    [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:self.context];
    [self userWithID:1 firstName:@"Ben" lastName:@"Boykewich" age:23 inContext:self.context];
    [self userWithID:2 firstName:@"Ricky" lastName:@"Underwood" age:19 inContext:self.context];
    [self userWithID:3 firstName:@"Grace" lastName:@"Bowman" age:20 inContext:self.context];
    [self userWithID:4 firstName:@"Adrian" lastName:@"Lee" age:20 inContext:self.context];

    [self.context save:nil];
}

- (void)tearDown
{
    [self.context rollback];

    [super tearDown];
}

- (void)testUsersCount
{
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    NSArray *results = [self.context executeFetchRequest:request error:&error];

    XCTAssertEqual(results.count, 5);
}

- (void)testDictionaryOfIDsAndFetchedIDsUsingPredicate
{
    NSMutableDictionary *results = [NSManagedObject dictionaryOfIDsAndFetchedIDsInContext:self.context
                                                                            usingLocalKey:@"userID"
                                                                            forEntityName:@"User"];

    XCTAssertEqual(results.count, 5);
}

- (void)testMapChanges
{
    id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

    __block NSInteger inserted = 0;
    __block NSInteger updated = 0;

    [NSManagedObject andy_mapChanges:JSON
                            localKey:@"userID"
                           remoteKey:@"id"
                      usingPredicate:nil
                           inContext:self.context
                       forEntityName:@"User"
                            inserted:^(NSDictionary *objectDict) {
                                inserted++;
                            } updated:^(NSDictionary *objectDict, NSManagedObject *object) {
                                updated++;
                            }];

    XCTAssertEqual(inserted, 2);
    XCTAssertEqual(updated, 4);
}

- (void)testMapChangesB
{
    id JSON = [self JSONObjectWithContentsOfFile:@"users2.json"];

    __block NSInteger inserted = 0;
    __block NSInteger updated = 0;

    [NSManagedObject andy_mapChanges:JSON
                            localKey:@"userID"
                           remoteKey:@"id"
                      usingPredicate:nil
                           inContext:self.context
                       forEntityName:@"User"
                            inserted:^(NSDictionary *objectDict) {
                                inserted++;
                            } updated:^(NSDictionary *objectDict, NSManagedObject *object) {
                                updated++;
                            }];

    XCTAssertEqual(inserted, 0);
    XCTAssertEqual(updated, 1);
}

@end
