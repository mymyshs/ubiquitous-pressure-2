//
//  GraphViewController.swift
//  PressureMeter
//
//  Created by Mayumi on 24/06/2017.
//  Copyright © 2017 Mayumi. All rights reserved.
//

import UIKit


class GraphViewController: UIViewController {

	@IBOutlet weak var graphView: ScrollableGraphView!

	var data: [Double]?
	var labels: [String]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let data = data, let labels = labels else {
			return
		}
		graphView?.set(data: data, withLabels: labels)
	}
	
}


