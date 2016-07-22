import Foundation
import CoreData
import DATAObjectIDs

public class DATAFilter: NSObject {
    public struct Operation : OptionSetType {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let Insert = Operation(rawValue: 1 << 0)
        public static let Update = Operation(rawValue: 1 << 1)
        public static let Delete = Operation(rawValue: 1 << 2)
        public static let All: Operation = [.Insert, .Update, .Delete]
    }

    public class func changes(changes: [[String : AnyObject]],
                              inEntityNamed entityName: String,
                                            localPrimaryKey: String,
                                            remotePrimaryKey: String,
                                            context: NSManagedObjectContext,
                                            inserted: (JSON: [String : AnyObject]) -> Void,
                                            updated: (JSON: [String : AnyObject], updatedObject: NSManagedObject) -> Void){
        self.changes(changes, inEntityNamed: entityName, predicate: nil, operations: .All, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: inserted, updated: updated)
    }

    public class func changes(changes: [[String : AnyObject]],
                              inEntityNamed entityName: String,
                                            predicate: NSPredicate?,
                                            operations: Operation,
                                            localPrimaryKey: String,
                                            remotePrimaryKey: String,
                                            context: NSManagedObjectContext,
                                            inserted: (JSON: [String : AnyObject]) -> Void,
                                            updated: (JSON: [String : AnyObject], updatedObject: NSManagedObject) -> Void) {
        // Get primary key values and objectIDs of objects in "context" as [primary key: objectID]
        // Also deletes all objects that don't have a primary key or that have the same primary key already found in the context
        let dictionaryIDAndObjectID = DATAObjectIDs.objectIDsInEntityNamed(entityName, withAttributesNamed: localPrimaryKey, context: context, predicate: predicate) as! [NSObject : NSManagedObjectID]
        // Get array of primary keys
        let fetchedObjectIDs = Array(dictionaryIDAndObjectID.keys)
        // Extract array of primary keys from "changes" (remote primary keys)
        let remoteObjectIDsOpt = changes.map({$0[remotePrimaryKey]})
        // Filter out nil values
        let remoteObjectIDs = (remoteObjectIDsOpt.filter({$0 != nil}) as! [NSObject!]) as![NSObject]

        // Construct dictionary with remote primary keys as keys and "changes" itself as objects
        var remoteIDAndChange: [NSObject : [String : AnyObject]] = Dictionary()
        for (key, value) in zip(remoteObjectIDs, changes) {
            remoteIDAndChange[key] = value
        }
        
        // Create array with primary keys that are present both locally and remotely
        // Create Set from remote primary keys
        var intersection = Set(remoteObjectIDs)
        // Intersect remote primary keys with local primary keys so we have all IDs that are present in both
        intersection.intersectInPlace(Set(fetchedObjectIDs))
        // Get all IDs back in an array
        let updatedObjectIDs = Array(intersection)
        
        
        // Create array with primary keys that are present locally but not remotely
        var deletedObjectIDs = fetchedObjectIDs
        // Filter values...
        deletedObjectIDs = deletedObjectIDs.filter {value in
            //... that are not contained in remoteObjectIDs
            !remoteObjectIDs.contains({$0.isEqual(value)})
        }

        // Create array with primary keys that are only present remotely
        var insertedObjectIDs = remoteObjectIDs
        // Filter values...
        insertedObjectIDs = insertedObjectIDs.filter {value in
            //... that are not contained in fetchedObjectIDs
            !fetchedObjectIDs.contains({$0.isEqual(value)})
        }

        // Remove objects from context that aren't present remotely
        if operations.contains(.Delete) {
            for fetchedID in deletedObjectIDs {
                let objectID = dictionaryIDAndObjectID[fetchedID]!
                let object = context.objectWithID(objectID)
                context.deleteObject(object)
            }
        }

        // Call "inserted" closure for every object that's not present locally
        if operations.contains(.Insert) {
            for fetchedID in insertedObjectIDs {
                // Get dictionary that represents the new object
                let objectDictionary = remoteIDAndChange[fetchedID]!
                inserted(JSON: objectDictionary)
            }
        }

        // Call "updated" closure for every object that's present both locally and remotely
        if operations.contains(.Update) {
            for fetchedID in updatedObjectIDs {
                // Get dictionary that represents the updated object
                let objectDictionary = remoteIDAndChange[fetchedID]!
                // Get the objectID of the local version of the object
                let objectID = dictionaryIDAndObjectID[fetchedID]!
                // Get the actual object
                let object = context.objectWithID(objectID)
                updated(JSON: objectDictionary, updatedObject: object)
            }
        }
    }
}
