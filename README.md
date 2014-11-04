# NSManagedObject-ANDYMapChanges

[![CI Status](http://img.shields.io/travis/NSElvis/NSManagedObject-ANDYMapChanges.svg?style=flat)](https://travis-ci.org/NSElvis/NSManagedObject-ANDYMapChanges)
[![Version](https://img.shields.io/cocoapods/v/NSManagedObject-ANDYMapChanges.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYMapChanges)
[![License](https://img.shields.io/cocoapods/l/NSManagedObject-ANDYMapChanges.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYMapChanges)
[![Platform](https://img.shields.io/cocoapods/p/NSManagedObject-ANDYMapChanges.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYMapChanges)

This is a category on NSManagedObject that helps you to evaluate insertions, deletions and updates by comparing your JSON dictionary with your CoreData local objects.

## The magic

```objc
+ (void)andy_mapChanges:(NSArray *)changes
              inContext:(NSManagedObjectContext *)context
          forEntityName:entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated;
```

*Take a look at the [wiki](https://github.com/NSElvis/NSManagedObject-ANDYMapChanges/wiki) if you need more control over which local and remote keys are used. Also you can specify a predicate which can be useful for things like processing changes only for users in a specific store.*

## How to use

```objc
- (void)importObjects:(NSArray *)objects usingContext:(NSManagedObjectContext *)context
{
    [NSManagedObject andy_mapChanges:JSON
                           inContext:context
                       forEntityName:entityName
                            inserted:^(NSDictionary *objectDict) {
                                ANDYUser *user = [ANDYUser insertInManagedObjectContext:context];
                                [user fillObjectWithAttributes:objectDict];
                            } updated:^(NSDictionary *objectDict, NSManagedObject *object) {
                                ANDYUser *user = (ANDYUser *)object;
                                [user fillObjectWithAttributes:objectDict];
                            }];

    [context save:nil];
}
```

## Usage

To run the example project, clone the repo, and open the `.xcodeproj` from the Demo directory.

## Requirements

`iOS 7.0`

## Installation

**NSManagedObject-ANDYMapChanges** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

`pod 'NSManagedObject-ANDYMapChanges'`

## Author

Elvis Nuñez, hello@nselvis.com

## License

**NSManagedObject-ANDYMapChanges** is available under the MIT license. See the LICENSE file for more info.

