//
//  RealmData.swift
//  PressureMeter
//
//  Created by Mayumi on 24/06/2017.
//  Copyright © 2017 Mayumi. All rights reserved.
//

import Foundation
import RealmSwift

class PressureData : Object {
	
	dynamic var createdAt : Date = Date()
	dynamic var pd : Double = 0
	
	func save() {
		do {
			let realm = try Realm()
			try realm.write {
				realm.add(self)
			}
		} catch let error as NSError {
			fatalError(error.localizedDescription)
		}
	}
	
}
