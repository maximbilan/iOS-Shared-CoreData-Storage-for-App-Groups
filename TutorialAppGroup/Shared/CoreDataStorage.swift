//
//  CoreDataStorage.swift
//  TutorialAppGroup
//
//  Created by Maxim on 10/18/15.
//  Copyright © 2015 Maxim. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataStorage {
	
	// MARK: - Shared Instance
	
	class var sharedInstance : CoreDataStorage {
		struct Static {
			static var onceToken: dispatch_once_t = 0
			static var instance: CoreDataStorage? = nil
		}
		dispatch_once(&Static.onceToken) {
			Static.instance = CoreDataStorage()
		}
		return Static.instance!
	}
	
	// MARK: - Initialization
	
	init() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSavePrivateQueueContext:", name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueCtxt)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSaveMainQueueContext:", name: NSManagedObjectContextDidSaveNotification, object: self.mainQueueCtxt)
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	// MARK: - Notifications
	
	@objc func contextDidSavePrivateQueueContext(notification: NSNotification) {
		if let context = self.mainQueueCtxt {
			self.synced(self, closure: { () -> () in
				context.performBlock({() -> Void in
					context.mergeChangesFromContextDidSaveNotification(notification)
				})
			})
		}
	}
	
	@objc func contextDidSaveMainQueueContext(notification: NSNotification) {
		if let context = self.privateQueueCtxt {
			self.synced(self, closure: { () -> () in
				context.performBlock({() -> Void in
					context.mergeChangesFromContextDidSaveNotification(notification)
				})
			})
		}
	}
	
	func synced(lock: AnyObject, closure: () -> ()) {
		objc_sync_enter(lock)
		closure()
		objc_sync_exit(lock)
	}
	
	// MARK: - Core Data stack
	
	lazy var applicationDocumentsDirectory: NSURL = {
		// The directory the application uses to store the Core Data store file. This code uses a directory named 'Bundle identifier' in the application's documents Application Support directory.
		let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		return urls[urls.count-1]
		}()
	
	lazy var managedObjectModel: NSManagedObjectModel = {
		// The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
		let modelURL = NSBundle.mainBundle().URLForResource("TutorialAppGroup", withExtension: "momd")!
		return NSManagedObjectModel(contentsOfURL: modelURL)!
		}()
	
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
		// The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
		// Create the coordinator and store
		var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		
		let directory = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.maximbilan.tutorialappgroup")!
		
		let url = directory.URLByAppendingPathComponent("TutorialAppGroup.sqlite")
		
		do {
			try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
		} catch var error as NSError {
			coordinator = nil
			NSLog("Unresolved error \(error), \(error.userInfo)")
			abort()
		} catch {
			fatalError()
		}
		print("\(coordinator?.persistentStores)")
		return coordinator
		}()
	
	// MARK: - NSManagedObject Contexts
	
	public class func mainQueueContext() -> NSManagedObjectContext {
		return self.sharedInstance.mainQueueCtxt!
	}
	
	public class func privateQueueContext() -> NSManagedObjectContext {
		return self.sharedInstance.privateQueueCtxt!
	}
	
	lazy var mainQueueCtxt: NSManagedObjectContext? = {
		// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		var managedObjectContext = NSManagedObjectContext(concurrencyType:.MainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		return managedObjectContext
		}()
	
	lazy var privateQueueCtxt: NSManagedObjectContext? = {
		// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		var managedObjectContext = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		return managedObjectContext
		}()
	
	// MARK: - Core Data Saving support
	
	public class func saveContext(context: NSManagedObjectContext?) {
		if let moc = context {
			if moc.hasChanges {
				do {
					try moc.save()
				} catch {
				}
			}
		}
	}
	
}

extension NSManagedObject {
	
	public class func findAllForEntity(entityName: String, context: NSManagedObjectContext) -> [AnyObject]? {
		let request = NSFetchRequest(entityName: entityName)
		let result: [AnyObject]?
		do {
			result = try context.executeFetchRequest(request)
		} catch let error as NSError {
			print(error)
			result = nil
		}
		return result
	}
}
