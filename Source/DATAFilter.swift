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
                                            inserted: (objectJSON: [String: AnyObject]) -> Void,
                                            updated: (objectJSON: [String: AnyObject], updatedObject: NSManagedObject) -> Void){
        self.changes(changes, inEntityNamed: entityName, predicate: nil, operations: .All, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: inserted, updated: updated)
    }

    public class func changes(changes: [[String : AnyObject]],
                              inEntityNamed entityName: String,
                                            predicate: NSPredicate?,
                                            operations: Operation,
                                            localPrimaryKey: String,
                                            remotePrimaryKey: String,
                                            context: NSManagedObjectContext,
                                            inserted: (objectJSON: [String: AnyObject]) -> Void,
                                            updated: (objectJSON: [String: AnyObject], updatedObject: NSManagedObject) -> Void) {
        // Get primary key values and objectIDs of objects in "context" as [primary key: objectID] (type: [NSObject: NSManagedObjectID])
        // Also deletes all objects that don't have a primary key or that have the same primary key already found in the context
        let dictionaryIDAndObjectID = DATAObjectIDs.objectIDsInEntityNamed(entityName, withAttributesNamed: localPrimaryKey, context: context, predicate: predicate)
        // Get array of primary keys
        let fetchedObjectIDs: [AnyObject] = Array(dictionaryIDAndObjectID.keys)
        // Extract array of primary keys from "changes" (remote primary keys)
        let remoteObjectIDsOpt = changes.map({$0[remotePrimaryKey]})
        // Filter out nil values
        let remoteObjectIDs = remoteObjectIDsOpt.filter({$0 != nil}) as! [AnyObject!]

        // Construct dictionary with remote primary keys as keys and "changes" itself as objects (type: [NSObject: [String: AnyObject]])
        let remoteIDAndChange = NSDictionary(objects: changes as [AnyObject], forKeys: remoteObjectIDs as NSArray as! [NSCopying])
        
        // Create array with primary keys that are present both lacally and remotely
        // Create Set from remote primary keys
        let intersection = NSMutableSet(array: remoteObjectIDs as [AnyObject])
        // Intersect remote primary keys with local primary keys so we have all IDs that are present in both
        intersection.intersectSet(NSSet(array: fetchedObjectIDs) as Set<NSObject>)
        // Get all IDs back in an array
        let updatedObjectIDs = intersection.allObjects

        // Create array with primary keys that are present locally but not remotely
        var deletedObjectIDs = fetchedObjectIDs
        deletedObjectIDs = deletedObjectIDs.filter {value in
            !remoteObjectIDs.contains({$0.isEqual(value)})
        }

        // Create array with primary keys that are only present remotely
        var insertedObjectIDs = remoteObjectIDs
        insertedObjectIDs = insertedObjectIDs.filter {value in
            !fetchedObjectIDs.contains({$0.isEqual(value)})
        }

        // Remove objects from context that aren't present remotely
        if operations.contains(.Delete) {
            for fetchedID in deletedObjectIDs {
                let objectID = dictionaryIDAndObjectID[fetchedID as! NSObject] as! NSManagedObjectID
                let object = context.objectWithID(objectID)
                context.deleteObject(object)
            }
        }

        // Call "inserted" closure for every object that's not present locally
        if operations.contains(.Insert) {
            for fetchedID in insertedObjectIDs as NSArray as! [NSCopying] {
                // Get dictionary that represents the new object
                let objectDictionary = remoteIDAndChange[fetchedID] as! [String: AnyObject]
                inserted(objectJSON: objectDictionary)
            }
        }

        // Call "updated" closure for every object that's present both locally and remotely
        if operations.contains(.Update) {
            for fetchedID in updatedObjectIDs as! [NSCopying] {
                // Get dictionary that represents the updated object
                let objectDictionary = remoteIDAndChange[fetchedID] as! [String: AnyObject]
                // Get the objectID of the local version of the object
                let objectID = dictionaryIDAndObjectID[fetchedID as! NSObject] as! NSManagedObjectID
                // Get the actual object
                let object = context.objectWithID(objectID)
                updated(objectJSON: objectDictionary, updatedObject: object)
            }
        }
    }
}
