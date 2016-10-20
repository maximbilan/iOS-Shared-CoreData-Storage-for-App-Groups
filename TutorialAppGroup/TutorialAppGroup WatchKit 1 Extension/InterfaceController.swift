//
//  InterfaceController.swift
//  TutorialAppGroup WatchKit 1 Extension
//
//  Created by Maxim on 10/18/15.
//  Copyright © 2015 Maxim. All rights reserved.
//

import WatchKit
import Foundation
import CoreData

class InterfaceController: WKInterfaceController {

	@IBOutlet var titleLabel: WKInterfaceLabel!
	@IBOutlet var valueLabel: WKInterfaceLabel!
	@IBOutlet var incrementButton: WKInterfaceButton!
	
	let context = CoreDataStorage.mainQueueContext()
	var counter: Counter?
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		fetchData()
	}

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

	// MARK: - Logic
	
	func fetchData() {
		self.context.performAndWait{ () -> Void in
			
			let counter = NSManagedObject.findAllForEntity("Counter", context: self.context)
			
			if (counter?.last != nil) {
				self.counter = (counter?.last as! Counter)
			}
			else {
				self.counter = (NSEntityDescription.insertNewObject(forEntityName: "Counter", into: self.context) as! Counter)
				self.counter?.title = "Counter"
				self.counter?.value = 0
			}
			
			self.updateUI()
		}
	}
	
	func updateUI() {
		titleLabel.setText(counter?.title)
		valueLabel.setText(counter?.value?.stringValue)
	}
	
	func save() {
		CoreDataStorage.saveContext(self.context)
	}
	
	// MARK: - Actions
	
	@IBAction func incrementButtonAction() {
		let value = counter?.value?.intValue
		counter?.value = (value! + 1) as NSNumber?
		
		updateUI()
		save()
	}
	
}
