# DATAFilter

[![CI Status](http://img.shields.io/travis/NSElvis/DATAFilter.svg?style=flat)](https://travis-ci.org/NSElvis/DATAFilter)
[![Version](https://img.shields.io/cocoapods/v/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)
[![License](https://img.shields.io/cocoapods/l/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)
[![Platform](https://img.shields.io/cocoapods/p/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)

This is a category on NSManagedObject that helps you to evaluate insertions, deletions and updates by comparing your JSON dictionary with your CoreData local objects. It also provides uniquing for you locally stored objects.

## The magic

```objc
+ (void)changes:(NSArray *)changes
              inContext:(NSManagedObjectContext *)context
          forEntityName:(NSString *)entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated;
```

## How to use

```objc
- (void)importObjects:(NSArray *)objects usingContext:(NSManagedObjectContext *)context error:(NSError *)error
{
    [NSManagedObject changes:JSON
                           inContext:context
                       forEntityName:@"User"
                            inserted:^(NSDictionary *objectDict) {
                                ANDYUser *user = [ANDYUser insertInManagedObjectContext:context];
                                [user fillObjectWithAttributes:objectDict];
                            } updated:^(NSDictionary *objectDict, NSManagedObject *object) {
                                ANDYUser *user = (ANDYUser *)object;
                                [user fillObjectWithAttributes:objectDict];
                            }];

    [context save:&error];
}
```

## Local and Remote keys

`localKey` is the name of the local primaryKey, if it's a user it could be `remoteID`.
`remoteKey` is the name of the key from JSON, if it's a user it could be just `id`.

The convenience method that doesn't contain this attributes, fallsback to `remoteID` for the `localKey` and `id` for the `remoteKey`.

## Predicate

Use the predicate to filter out mapped changes. For example if the JSON response belongs to only inactive users, you could have a predicate like this:

```objc
NSPredicate *predicate = [NSString stringWithFormat:@"inactive = YES"];
```

***

*As a side note, you should use a [fancier property mapper](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper/blob/master/README.md) that does the `fillObjectWithAttributes` part for you.*

## Usage

To run the example project, clone the repo, and open the `.xcodeproj` from the Demo directory.

## Requirements

`iOS 7.0`, `Core Data`

## Installation

**DATAFilter** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DATAFilter'
```

## Author

Elvis Nuñez, [hello@nselvis.com](mailto:hello@nselvis.com)

## License

**DATAFilter** is available under the MIT license. See the [LICENSE](https://github.com/NSElvis/DATAFilter/blob/master/LICENSE.md) file for more info.

