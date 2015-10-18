//
//  InterfaceController.swift
//  TutorialAppGroup WatchKit 1 Extension
//
//  Created by Maxim on 10/18/15.
//  Copyright © 2015 Maxim. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

	@IBOutlet var titleLabel: WKInterfaceLabel!
	@IBOutlet var valueLabel: WKInterfaceLabel!
	@IBOutlet var incrementButton: WKInterfaceButton!
	
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

	@IBAction func incrementButtonAction() {
	}
	
}
