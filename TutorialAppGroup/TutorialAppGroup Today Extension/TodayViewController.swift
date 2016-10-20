//
//  TodayViewController.swift
//  Tutorial App Group Today Extension
//
//  Created by Maxim on 10/18/15.
//  Copyright © 2015 Maxim. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData

class TodayViewController: UIViewController, NCWidgetProviding {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var valueLabel: UILabel!
	@IBOutlet weak var incrementButton: UIButton!
	
	let context = CoreDataStorage.mainQueueContext()
	var counter: Counter?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.preferredContentSize.height = 50
		
		fetchData()
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

		fetchData()
        completionHandler(NCUpdateResult.newData)
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
