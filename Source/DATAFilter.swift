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
    
    public struct SyncStatus: OptionSetType {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let Synced = SyncStatus(rawValue: 1 << 0)
        public static let Created = SyncStatus(rawValue: 1 << 1)
        public static let Deleted = SyncStatus(rawValue: 1 << 2)
        public static let All: SyncStatus = [.Synced, .Created, .Deleted]
        // .None means "Ignore SyncStatus".
        // With this option DATAFilter should behave like it would behave if there was no `SyncStatus`.
        public static let None: SyncStatus = []
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
        self.changes(changes, inEntityNamed: entityName, predicate: predicate, operations: operations, syncStatus: .None, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: inserted, updated: updated)
    }
    
    public class func changes(changes: [[String : AnyObject]],
                               inEntityNamed entityName: String,
                                             predicate: NSPredicate?,
                                             operations: Operation,
                                             syncStatus: SyncStatus,
                                             localPrimaryKey: String,
                                             remotePrimaryKey: String,
                                             context: NSManagedObjectContext,
                                             inserted: (JSON: [String : AnyObject]) -> Void,
                                             updated: (JSON: [String : AnyObject], updatedObject: NSManagedObject) -> Void)
                    -> ([NSManagedObject], [NSManagedObject]) {
        // `DATAObjectIDs.objectIDsInEntityNamed` also deletes all objects that don't have a primary key or that have the same primary key already found in the context
        let primaryKeysAndObjectIDs = DATAObjectIDs.objectIDsInEntityNamed(entityName, withAttributesNamed: localPrimaryKey, context: context, predicate: predicate) as! [NSObject : NSManagedObjectID]
        let localPrimaryKeys = Array(primaryKeysAndObjectIDs.keys)
        let remotePrimaryKeys = changes.map { $0[remotePrimaryKey] }
        let remotePrimaryKeysWithoutNils = (remotePrimaryKeys.filter { $0 != nil } as! [NSObject!]) as! [NSObject]
        
        var remotePrimaryKeysAndChanges = [NSObject : [String : AnyObject]]()
        for (primaryKey, change) in zip(remotePrimaryKeysWithoutNils, changes) {
            remotePrimaryKeysAndChanges[primaryKey] = change
        }
        
        var intersection = Set(remotePrimaryKeysWithoutNils)
        intersection.intersectInPlace(Set(localPrimaryKeys))
        var updatedObjectIDs = Array(intersection)
        
        
        var deletedObjectIDs = localPrimaryKeys
        deletedObjectIDs = deletedObjectIDs.filter { value in
            !remotePrimaryKeysWithoutNils.contains { $0.isEqual(value) }
        }
        
        var insertedObjectIDs = remotePrimaryKeysWithoutNils
        insertedObjectIDs = insertedObjectIDs.filter { value in
            !localPrimaryKeys.contains { $0.isEqual(value) }
        }
                        
        // If an object is created locally it will now be contained in `deletedObjectIDs`
        var created = [NSManagedObject]()
        if syncStatus.contains(.Created) {
            for (i, fetchedID) in deletedObjectIDs.enumerate().reverse() {
                let objectID = primaryKeysAndObjectIDs[fetchedID]!
                let object = context.objectWithID(objectID)
                if object.valueForKey("syncStatus") as! Int == 1 << 1 {
                    created.append(object)
                    deletedObjectIDs.removeAtIndex(i)
                }
            }
        }
        // If an object is deleted locally it will now be contained in `updatedObjectIDs`
        var deleted = [NSManagedObject]()
        if syncStatus.contains(.Deleted) {
            for (i, fetchedID) in updatedObjectIDs.enumerate().reverse() {
                let objectID = primaryKeysAndObjectIDs[fetchedID]!
                let object = context.objectWithID(objectID)
                if object.valueForKey("syncStatus") as! Int == 1 << 2 {
                    deleted.append(object)
                    updatedObjectIDs.removeAtIndex(i)
                }
            }
        }
            
        if operations.contains(.Delete) {
            for fetchedID in deletedObjectIDs {
                let objectID = primaryKeysAndObjectIDs[fetchedID]!
                let object = context.objectWithID(objectID)
                context.deleteObject(object)
            }
        }
        
        if operations.contains(.Insert) {
            for fetchedID in insertedObjectIDs {
                let objectDictionary = remotePrimaryKeysAndChanges[fetchedID]!
                inserted(JSON: objectDictionary)
            }
        }
                        
        if operations.contains(.Update) {
            for fetchedID in updatedObjectIDs {
                let objectDictionary = remotePrimaryKeysAndChanges[fetchedID]!
                let objectID = primaryKeysAndObjectIDs[fetchedID]!
                let object = context.objectWithID(objectID)
                updated(JSON: objectDictionary, updatedObject: object)
            }
        }
                        
        return (created, deleted)
    }

}
