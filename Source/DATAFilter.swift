import Foundation
import CoreData
import DATAObjectIDs

public struct DATAFilterOperation : OptionSetType {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let Insert = DATAFilterOperation(rawValue: 1 << 0)
    public static let Update = DATAFilterOperation(rawValue: 1 << 1)
    public static let Delete = DATAFilterOperation(rawValue: 1 << 2)
    public static let All: DATAFilterOperation = [.Insert, .Update, .Delete]
}

@objc public class DATAFilter: NSObject {
    public class func changes(changes: NSArray,
                              inEntityNamed entityName: String,
                                            localPrimaryKey: String,
                                            remotePrimaryKey: String,
                                            context: NSManagedObjectContext,
                                            inserted: (objectJSON: NSDictionary) -> Void,
                                            updated: (objectJSON: NSDictionary, updatedObject: NSManagedObject) -> Void){
        self.changes(changes, inEntityNamed: entityName, predicate: nil, operations: .All, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: inserted, updated: updated)
    }

    public class func changes(changes: NSArray,
                              inEntityNamed entityName: String,
                                            predicate: NSPredicate?,
                                            operations: DATAFilterOperation,
                                            localPrimaryKey: String,
                                            remotePrimaryKey: String,
                                            context: NSManagedObjectContext,
                                            inserted: (objectJSON: NSDictionary) -> Void,
                                            updated: (objectJSON: NSDictionary, updatedObject: NSManagedObject) -> Void) {
        let dictionaryIDAndObjectID = DATAObjectIDs.objectIDsInEntityNamed(entityName, withAttributesNamed: localPrimaryKey, context: context, predicate: predicate)
        let fetchedObjectIDs = Array(dictionaryIDAndObjectID.keys)
        let remoteObjectIDs = changes.valueForKey(remotePrimaryKey).mutableCopy() as! NSMutableArray
        remoteObjectIDs.removeObject(NSNull())

        let remoteIDAndChange = NSDictionary(objects: changes as [AnyObject], forKeys: remoteObjectIDs as! [NSCopying])
        let intersection = NSMutableSet(array: remoteObjectIDs as [AnyObject])
        intersection.intersectSet(NSSet(array: fetchedObjectIDs) as Set<NSObject>)
        let updatedObjectIDs = intersection.allObjects

        let deletedObjectIDs = NSMutableArray(array: fetchedObjectIDs)
        deletedObjectIDs.removeObjectsInArray(remoteObjectIDs as [AnyObject])

        let insertedObjectIDs = remoteObjectIDs.mutableCopy() as! NSMutableArray
        insertedObjectIDs.removeObjectsInArray(fetchedObjectIDs as [AnyObject])

        if operations.contains(.Delete) {
            for fetchedID in deletedObjectIDs {
                let objectID = dictionaryIDAndObjectID[fetchedID as! NSObject] as! NSManagedObjectID
                let object = context.objectWithID(objectID)
                context.deleteObject(object)
            }
        }

        if operations.contains(.Insert) {
            for fetchedID in insertedObjectIDs as! [NSCopying] {
                let objectDictionary = remoteIDAndChange[fetchedID] as! NSDictionary
                inserted(objectJSON: objectDictionary)
            }
        }

        if operations.contains(.Update) {
            for fetchedID in updatedObjectIDs as! [NSCopying] {
                let objectDictionary = remoteIDAndChange[fetchedID] as! NSDictionary
                let objectID = dictionaryIDAndObjectID[fetchedID as! NSObject] as! NSManagedObjectID
                let object = context.objectWithID(objectID)
                updated(objectJSON: objectDictionary, updatedObject: object)
            }
        }
    }
}
