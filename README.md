# DATAFilter

[![Version](https://img.shields.io/cocoapods/v/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)
[![License](https://img.shields.io/cocoapods/l/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)
[![Platform](https://img.shields.io/cocoapods/p/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)

Helps you filter insertions, deletions and updates by comparing your JSON dictionary with your Core Data local objects. It also provides uniquing for you locally stored objects and automatic removal of not found ones.

## The magic

```swift
public class func changes(changes: NSArray, 
      inEntityNamed entityName: String, 
      localPrimaryKey: String, 
      remotePrimaryKey: String, 
      context: NSManagedObjectContext, 
      inserted: (objectJSON: NSDictionary) -> Void, 
      updated: (objectJSON: NSDictionary, updatedObject: NSManagedObject) -> Void)
```

## How to use

```swift
func importObjects(JSON: [AnyObject], context: NSManagedObjectContext) {
    DATAFilter.changes(JSON,
                       inEntityNamed: "User",
                       localPrimaryKey: "remoteID",
                       remotePrimaryKey: "id",
                       context: context,
                       inserted: { objectJSON in
                        let user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: context)
                        user.fillObjectWithAttributes(JSON)
        }) { objectJSON, updatedObject in
            if let user = updatedObject as? User {
                user.fillObjectWithAttributes(JSON)
            }
    }
}
```

## Requirements

`iOS 7.0`, `Core Data`

## Installation

**DATAFilter** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DATAFilter'
```

## Author

Elvis Nuñez, [elvisnunez@me.com](mailto:elvisnunez@me.com)

## License

**DATAFilter** is available under the MIT license. See the [LICENSE](https://github.com/3lvis/DATAFilter/blob/master/LICENSE.md) file for more info.
