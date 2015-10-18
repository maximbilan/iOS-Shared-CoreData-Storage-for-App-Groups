//
//  Counter+CoreDataProperties.swift
//  TutorialAppGroup
//
//  Created by Maxim on 10/18/15.
//  Copyright © 2015 Maxim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Counter {

    @NSManaged var value: NSNumber?
    @NSManaged var title: String?

}
