# iOS Shared CoreData Storage for App Groups

Sometimes <i>iOS</i> applications have some extensions, for example <i>Today Extensions</i>, or <i>Apple Watch Extensions</i>. And sometimes no sense to implement data storage for every target. In this post I tell how to create a one data storage for iOS application and his extensions.

First of all you need to create app groups for your application. Go to <a href="https://developer.apple.com/membercenter/">Apple Developer Member Center</a> and register app group. Fill the description and identifier and follow the instructions.

![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/1.png)
![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/2.png)
![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/3.png)

After that when you will create identifier for application or extension, don’t forget enable service <i>App Groups</i>.

![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/4.png)

Then go to the application or extension and edit services. It’s really simple, see the next screenshots:

![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/5.png)
![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/6.png)
![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/7.png)
![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/8.png)
![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/9.png)

And please, perform this procedure for all extensions of the group. It’s all settings, now open the Xcode and let’s go to write code.

In the Xcode for each target enable <i>App Groups</i> in target settings.

![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/10.png)

Use <i>Core Data Storage</i> class. Implementation of this class see below:

<pre>
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
</pre>

<i>CoreData</i> class for working with your shared storage, also <i>NSManagedObject</i> extension for fetching data from entity.

I provide samples for iOS application, <i>Today Extension</i> and <i>WatchKit</i> app. See the screenshots:

![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/11.png)
![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/12.png)
![alt tag](https://raw.github.com/maximbilan/iOS-Shared-CoreData-Storage-for-App-Groups/master/screenshots/13.png)

You need to create context and CoreData object:

<pre>
let context = CoreDataStorage.mainQueueContext()
var counter: Counter?
</pre>

For fetching data please use the following code:

<pre>
func fetchData() {
	self.context.performBlockAndWait{ () -> Void in
		let counter = NSManagedObject.findAllForEntity("Counter", context: self.context)
		if (counter?.last != nil) {
			self.counter = (counter?.last as! Counter)
		}
		else {
			self.counter = (NSEntityDescription.insertNewObjectForEntityForName("Counter", inManagedObjectContext: self.context) as! Counter)
			self.counter?.title = "Counter"
			self.counter?.value = 0
		}
		
		self.updateUI()
	}
}
</pre>

For saving context:

<pre>
CoreDataStorage.saveContext(self.context)
</pre>

The full code you can find in this repository. Please feel free. Happy coding!

<b>NOTE:</b> In watchOS 2 and higher you should have to maintain two separate data stores. Group identifier is not working in this case. If either side is a "read-only" client and the <i>CoreData</i> datastore is small and changes infrequently you could potentially use the transferFile <i>WatchConnectivity API</i> to transfer the whole store each time it changes.
