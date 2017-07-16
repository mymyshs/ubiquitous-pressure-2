//
//  Location.swift
//  PressureMeter
//
//  Created by Mayumi on 24/06/2017.
//  Copyright © 2017 Mayumi. All rights reserved.
//

import Foundation
import CoreLocation

class LocationController: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .notDetermined:
			locationManager.requestWhenInUseAuthorization()
		case .restricted, .denied:
			break
		case .authorizedAlways, .authorizedWhenInUse:
			break
		}
	}
	
	if CLLocationManager.locationServicesEnabled() {
	locationManager = CLLocationManager()
	locationManager.delegate = self
	locationManager.startUpdatingLocation()
	}
	
	// 位置情報が更新されるたびに呼ばれる
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let newLocation = locations.last else {
			return
		}
		
		self.latTextField.text = "".appendingFormat("%.4f", newLocation.coordinate.latitude)
		self.lngTextField.text = "".appendingFormat("%.4f", newLocation.coordinate.longitude)
	}
	
	if CLLocationManager.locationServicesEnabled() {
	locationManager.stopUpdatingLocation()
	}
}
