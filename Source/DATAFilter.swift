import Foundation
import CoreData
import DATAObjectIDs

struct DATAFilterOperation : OptionSetType {
    let rawValue: Int

    static let Insert = DATAFilterOperation(rawValue: 1 << 0)
    static let Update = DATAFilterOperation(rawValue: 1 << 1)
    static let Delete = DATAFilterOperation(rawValue: 1 << 2)
    static let All = DATAFilterOperation(rawValue: 0)
}

struct DATAFilter {
    static func changes(changes: NSArray, inEntityNamed entityName: String, predicate: NSPredicate? = nil, operations: DATAFilterOperation = .All, localKey: String, remoteKey: String, context: NSManagedObjectContext, inserted: (objectJSON: NSDictionary) -> Void, updated: (objectJSON: NSDictionary, updatedObject: NSManagedObject) -> Void) {
        let dictionaryIDAndObjectID = DATAObjectIDs.objectIDsInEntityNamed(entityName, withAttributesNamed: localKey, context: context, predicate: predicate)
        let fetchedObjectIDs = Array(dictionaryIDAndObjectID.keys)
        let remoteObjectIDs = changes.valueForKey(remoteKey) as! NSMutableArray
        remoteObjectIDs.removeObject(NSNull())

        let remoteIDAndChange = NSDictionary(objects: changes as [AnyObject], forKeys: remoteObjectIDs as! [NSCopying])
        let intersection = NSMutableSet(array: remoteObjectIDs as [AnyObject])
        intersection.intersectSet(NSSet(array: fetchedObjectIDs) as Set<NSObject>)
        //let updatedObjectIDs = intersection.allObjects

        let deletedObjectIDs = NSMutableArray(array: fetchedObjectIDs)
        deletedObjectIDs.removeObjectsInArray(remoteObjectIDs as [AnyObject])

//        var insertedObjectIDs = remoteObjectIDs.mutableCopy() as! NSMutableArray
//        insertedObjectIDs.removeObjectsInArray(fetchedObjectIDs as [AnyObject])

        if operations == .Delete {
            for fetchedID in deletedObjectIDs {
                let objectID = dictionaryIDAndObjectID[fetchedID as! NSObject] as! NSManagedObjectID
                let object = context.objectWithID(objectID)
                context.deleteObject(object)
            }
        }
    }
}