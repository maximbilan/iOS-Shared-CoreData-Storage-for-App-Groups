//
//  ViewController.swift
//  TutorialAppGroup
//
//  Created by Maxim on 10/18/15.
//  Copyright © 2015 Maxim. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var valueLabel: UILabel!
	@IBOutlet weak var incrementButton: UIButton!
	
	var counter: Counter?
	let context = CoreDataStorage.mainQueueContext()
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
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

	// MARK: - Logic
	
	func updateUI() {
		titleLabel.text = counter?.title
		valueLabel.text = counter?.value?.stringValue
	}
	
	func save() {
		if let value = Int(self.valueLabel.text!) {
			self.counter?.value = value as NSNumber?
			CoreDataStorage.saveContext(self.context)
		}
	}
	
	// MARK: - Actions
	
	@IBAction func incrementButtonAction(_ sender: UIButton) {
		if let value = Int(self.valueLabel.text!) {
			counter?.value = (value + 1) as NSNumber?
		}
		
		updateUI()
		save()
	}

}
