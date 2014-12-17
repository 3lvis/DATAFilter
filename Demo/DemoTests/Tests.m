@import XCTest;

#import "NSManagedObject+ANDYMapChanges.h"

#import "NSManagedObject+ANDYObjectIDs.h"

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
    NSInteger count = [self.context countForFetchRequest:request error:&error];

    XCTAssertEqual(count, 5);
}

- (void)testMapChangesWithExplicitKeys
{
    NSDictionary *before = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:self.context
                                                                         usingLocalKey:@"userID"
                                                                         forEntityName:@"User"];

    id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

    __block NSInteger inserted = 0;
    __block NSInteger updated = 0;
    __block NSInteger deleted = before.count;

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
                                deleted--;
                            }];

    XCTAssertEqual(inserted, 2);
    XCTAssertEqual(updated, 4);
    XCTAssertEqual(deleted, 1);
}

- (void)testMapChangesWithInferredKeys
{
    NSDictionary *before = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:self.context
                                                                         usingLocalKey:@"userID"
                                                                         forEntityName:@"User"];

    id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

    __block NSInteger inserted = 0;
    __block NSInteger updated = 0;
    __block NSInteger deleted = before.count;

    [NSManagedObject andy_mapChanges:JSON
                      usingPredicate:nil
                           inContext:self.context
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
}

- (void)testMapChangesB
{
    NSDictionary *before = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:self.context
                                                                         usingLocalKey:@"userID"
                                                                         forEntityName:@"User"];

    id JSON = [self JSONObjectWithContentsOfFile:@"users2.json"];

    __block NSInteger inserted = 0;
    __block NSInteger updated = 0;
    __block NSInteger deleted = before.count;

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
                                deleted--;
                            }];

    XCTAssertEqual(inserted, 0);
    XCTAssertEqual(updated, 5);
    XCTAssertEqual(deleted, 0);
}

- (void)testMapChangesC
{
    NSDictionary *before = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:self.context
                                                                         usingLocalKey:@"userID"
                                                                         forEntityName:@"User"];

    id JSON = [self JSONObjectWithContentsOfFile:@"users3.json"];

    __block NSInteger inserted = 0;
    __block NSInteger updated = 0;
    __block NSInteger deleted = before.count;

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
                                deleted--;
                            }];

    XCTAssertEqual(inserted, 0);
    XCTAssertEqual(updated, 0);
    XCTAssertEqual(deleted, 5);
}

- (void)testUniquing
{
    [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:self.context];
    [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:self.context];
    [self userWithID:0 firstName:@"Amy" lastName:@"Juergens" age:21 inContext:self.context];
    [self.context save:nil];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    NSInteger numberOfUsers = [self.context countForFetchRequest:request error:nil];
    XCTAssertEqual(numberOfUsers, 8);

    id JSON = [self JSONObjectWithContentsOfFile:@"users.json"];

    [NSManagedObject andy_mapChanges:JSON
                      usingPredicate:nil
                           inContext:self.context
                       forEntityName:@"User"
                            inserted:nil
                             updated:nil];

    NSInteger deletedNumberOfUsers = [self.context countForFetchRequest:request error:nil];
    XCTAssertEqual(deletedNumberOfUsers, 4);
}

@end
