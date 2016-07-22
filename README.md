# DATAFilter

[![Version](https://img.shields.io/cocoapods/v/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)
[![License](https://img.shields.io/cocoapods/l/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)
[![Platform](https://img.shields.io/cocoapods/p/DATAFilter.svg?style=flat)](http://cocoadocs.org/docsets/DATAFilter)

Helps you filter insertions, deletions and updates by comparing your JSON dictionary with your Core Data local objects. It also provides uniquing for you locally stored objects and automatic removal of not found ones.

## The magic

```swift
public class func changes(changes: [[String : AnyObject]], 
      inEntityNamed entityName: String, 
      localPrimaryKey: String, 
      remotePrimaryKey: String, 
      context: NSManagedObjectContext, 
      inserted: (JSON: [String : AnyObject]) -> Void, 
      updated: (JSON: [String : AnyObject], updatedObject: NSManagedObject) -> Void)
```

## How to use

```swift
func importObjects(JSON: [[String : AnyObject]], context: NSManagedObjectContext) {
    DATAFilter.changes(JSON,
                       inEntityNamed: "User",
                       localPrimaryKey: "remoteID",
                       remotePrimaryKey: "id",
                       context: context,
                       inserted: { JSON in
            let user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: context)
            user.fillObjectWithAttributes(JSON)
        }) { JSON, updatedObject in
            if let user = updatedObject as? User {
                user.fillObjectWithAttributes(JSON)
            }
    }
}
```

## Local and remote primary keys

`localPrimaryKey` is the name of the local primary key, for example `id` or `remoteID`.
`remotePrimaryKey` is the name of the key from JSON, for example `id`.

## Predicate

Use the predicate to filter out mapped changes. For example if the JSON response belongs to only inactive users, you could have a predicate like this:

```swift
let predicate = NSPredicate(format: "inactive == %@", true)
```

---------------

*As a side note, you should use a [fancier property mapper](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper/blob/master/README.md) that does the `fillObjectWithAttributes` part for you.*

## Operations

`DATAFilter` also provides the option to set which operations should be run when filtering, by default `.All` is used but you could also set the option to just `.Insert` and `.Update` (avoiding removing items) or `.Update` and `.Delete` (avoiding updating items).

Usage goes like this:

```swift
DATAFilter.changes(JSONObjects,
    inEntityNamed: "User",
    predicate: nil,
    operations: [.Insert, .Update],
    localPrimaryKey: "remoteID",
    remotePrimaryKey: "id",
    context: backgroundContext,
    inserted: { JSON in
        // Do something with inserted items
    }, updated: { JSON, updatedObject in
        // Do something with updated items
})
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
