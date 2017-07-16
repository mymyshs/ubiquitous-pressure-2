//
//  ViewController.swift
//  PressureMeter
//
//  Created by Mayumi on 22/06/2017.
//  Copyright © 2017 Mayumi. All rights reserved.
//

// MARK: - Frameworks
import UIKit
import CoreLocation
import CoreMotion
//import RealmSwift
import SwiftyJSON
import MapKit

// MARK: - ViewController
class ViewController: UIViewController, CLLocationManagerDelegate {

// MARK: - IBOutlets
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var scrollableGraphView: ScrollableGraphView!
	@IBOutlet weak var pressureValueLabel: UILabel!
	@IBOutlet weak var altitudeValueLabel: UILabel!
	@IBOutlet weak var placeLabel: UILabel!
	@IBOutlet weak var i0: UIImageView!
	@IBOutlet weak var forecastLabel: UILabel!
	@IBOutlet weak var forecast02Label: UILabel!
	@IBOutlet weak var latitudeValueLabel: UILabel!
	@IBOutlet weak var sealevelLabel: UILabel!
	@IBOutlet weak var longitudeValueLabel: UILabel!
	@IBOutlet weak var d1: UILabel!
	@IBOutlet weak var d2: UILabel!
	@IBOutlet weak var d3: UILabel!
	@IBOutlet weak var d4: UILabel!
	@IBOutlet weak var i1: UIImageView!
	@IBOutlet weak var i2: UIImageView!
	@IBOutlet weak var i3: UIImageView!
	@IBOutlet weak var i4: UIImageView!
	@IBOutlet weak var p1: UILabel!
	@IBOutlet weak var p2: UILabel!
	@IBOutlet weak var p3: UILabel!
	@IBOutlet weak var p4: UILabel!
	@IBAction func postSNS(_ sender: UIBarButtonItem) {
		UIGraphicsBeginImageContext(self.view.bounds.size)
		self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
		let image = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		let texts: String = "posted from #yomaのばろめーたー"
		let activity = UIActivityViewController(activityItems: [image as Any] + [texts], applicationActivities: nil)
		present(activity, animated: true, completion: nil)
	}

// MARK: - Definitions

	var locationManager:CLLocationManager!
	let altimeter = CMAltimeter()

	var newlatitude: Double = 0.0
	var newlongitude: Double = 0.0
	let kPressureInitialVal = -0.0 // 初期値
	var pressureValue: Double = 0.0
	var altitudeValue: Double = 0.0

	var requestUrl: String = ""
	var tomorrow: String = ""
	var place: String = ""
	var forecast: String = ""

	// データ配列を定義
	var data = [Double]() // 気圧データを追加
	var labels = [String]()

	var lastUrl = ""

// MARK: - viewDidLoad
	override func viewDidLoad() {
		super.viewDidLoad()

		timeLabel.adjustsFontSizeToFitWidth = true

		self.navigationController?.isToolbarHidden = false
		self.navigationController?.toolbar.setBackgroundImage(UIImage(named: "toolbar.png"), forToolbarPosition: .bottom, barMetrics: .default)

		// LocationManager
		if CLLocationManager.locationServicesEnabled() {
			locationManager = CLLocationManager()
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
			// 位置情報取得間隔を指定．指定した値（メートル）移動したら位置情報を更新する．任意．
			locationManager.distanceFilter = 1000
			locationManager.startUpdatingLocation()
		}

		initGraphWithData()
		startUpdate()
		getTime()
	}
	
// MARK: - Location
	// GPSが消えたら取得をやめる
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if CLLocationManager.locationServicesEnabled() {
			locationManager.stopUpdatingLocation()
		}
	}

	// Locationを取得する許可
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

	// Location 次のデリゲートが呼ばれる
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let newLocation = locations.last,
			CLLocationCoordinate2DIsValid(newLocation.coordinate) else {
				self.latitudeValueLabel.text = "Error"
				self.longitudeValueLabel.text = "Error"
				self.altitudeValueLabel.text = "Error"
				return
			}
		
		// ラベルに取得した値を表示
		self.latitudeValueLabel.text = String(format: "Latitude %.1f", newLocation.coordinate.latitude)
		self.longitudeValueLabel.text = String(format: "Longitude %.1f", newLocation.coordinate.longitude)
		self.altitudeValueLabel.text = String(format: "Altitude %.2f m", newLocation.altitude)

		// 緯度と経度の入れ物を定義
		newlatitude = newLocation.coordinate.latitude
		newlongitude = newLocation.coordinate.longitude
		// print(self.newlatitude, self.newlongitude)
		
		// APIのURLを定義
		self.requestUrl = "http://api.openweathermap.org/data/2.5/forecast/daily?lat=\(newlatitude)&lon=\(newlongitude)&APPID=f1c66dadbc4c99d5e32b32cf168d9fc4"

		locationManager.stopUpdatingLocation()
		if (self.requestUrl != self.lastUrl) {
			print("\(String(describing: self.requestUrl))")
			getWeather()
			self.lastUrl = self.requestUrl
		}
		setMap()
	}

// MARK: - Weather
	func getWeather() {
		// openweathermapApiを用いて各情報を取得
		let url = URL(string: requestUrl)!
		let task = URLSession.shared.dataTask(with: url) {data, response, error
			in
			if error == nil {
				DispatchQueue.main.async {
					// Update UI
					// print("dispatchQueue")
					do {
						// リソースの取得が終わると、ここに書いた処理が実行
						let json = JSON(data: data!)
						let place = json["city"]["name"]
						let icon = json["list"][0]["weather"][0]["icon"]
						let main = json["list"][0]["weather"][0]["main"]
						let description = json["list"][0]["weather"][0]["description"]
						let sealevel = json["list"][0]["pressure"]
						self.placeLabel.text = "I'm at \(place)"
						self.i0.image = UIImage(named: "\(icon)" + ".image")
						self.forecastLabel.text = " \(main)"
						self.forecast02Label.text = " \(description)"
						self.sealevelLabel.text = "Pressure on the sea level is \(sealevel) hPa"

						let dateFormatter = DateFormatter()
						dateFormatter.dateFormat = "EEE"

						for n in 1...4 {
							let dt = json["list"][n]["dt"]
							let date = dt.double
							let unixTime = TimeInterval(date!)
							let stringTime = Date(timeIntervalSince1970: TimeInterval(unixTime))
							let day = dateFormatter.string(from: stringTime)
							let image = json["list"][n]["weather"][0]["icon"]
							let press = json["list"][n]["pressure"]
							let daysName = self.value(forKey: "d\(n)") as! UILabel
							daysName.text = String("\(day)").uppercased()
							let imageName = self.value(forKey: "i\(n)") as! UIImageView
							imageName.image = UIImage(named: "\(image)" + ".png")
							let pressName = self.value(forKey: "p\(n)") as! UILabel
							pressName.text = String("\(press) hPa")
						}
						// print(json)
					}
				}
			}
		}
		task.resume()
	}

// MARK: - 気圧センサーから取得開始
	func startUpdate() {
		print("** called startUpdate() **")
		// 更新周期を設定.
//		myMotionManager.accelerometerUpdateInterval = 0.1

		if (CMAltimeter.isRelativeAltitudeAvailable()) {
			altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: {
				data, error in

//				var deviceMotionUpdateInterval: TimeInterval { get set }

				print("** pressure data updated **")

				if error == nil {
					self.pressureValueLabel.text = String(format: "%.2f hPa", self.pressureValue*10)
					self.pressureValue = Double(data!.pressure)
					self.updateGraph()
					self.getTime()
				}
			})
		} else {
			print("not use altimeter")
		}
	}

// MARK: - Map
	func setMap() {
		// MapViewを生成
		let myMapView = MKMapView()
		myMapView.frame = mapView.frame
		let center = CLLocationCoordinate2DMake(self.newlatitude, self.newlongitude)
		myMapView.setCenter(center, animated: true)
		let span = MKCoordinateSpanMake(0.3, 0.3)
		let myRegion = MKCoordinateRegionMake(center, span)
		myMapView.region = myRegion
		self.view.addSubview(myMapView)
		let annotation = MKPointAnnotation()
		annotation.coordinate = center
		annotation.title = "Hi, there!"
		annotation.subtitle = "I'm here."
		myMapView.addAnnotation(annotation)
	}

	// グラフの更新
	func updateGraph() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "H:m" // 日付フォーマットの設定

		// 取得したデータをデータ配列に設定
		let dataEntry = self.pressureValue*10
		let dateObj = dateFormatter.string(from: Date())	// 日付文字列を得る

		if (data.count == 1 && data[0] == 0.0) {
			data.removeAll()
			data.append(dataEntry)
			labels.removeAll()
			labels.append(dateObj)
		} else {
			data.append(dataEntry)
			labels.append(dateObj)
		}

		// viewにチャートデータを設定
		// scrollableGraphView.shouldAnimateOnStartup = false
		scrollableGraphView.set(data: data, withLabels: labels)
		// scrollableGraphView.shouldAnimateOnStartup = true
	}

// MARK: - Graph
	func initGraphWithData(){
		// グラフの設定
		scrollableGraphView.shouldShowLabels = false

		scrollableGraphView.numberOfIntermediateReferenceLines = 2
		scrollableGraphView.lineWidth = 0.5
		scrollableGraphView.shouldFill = true
		scrollableGraphView.fillGradientType = ScrollableGraphViewGradientType.linear
		scrollableGraphView.backgroundFillColor = UIColor.lightGray
		scrollableGraphView.fillType = ScrollableGraphViewFillType.gradient
		scrollableGraphView.fillGradientStartColor = UIColor.white
		scrollableGraphView.fillGradientEndColor = UIColor.lightGray
		scrollableGraphView.lineColor = UIColor.white
		scrollableGraphView.referenceLineNumberOfDecimalPlaces = 2
		scrollableGraphView.referenceLineColor = UIColor.lightGray
		scrollableGraphView.referenceLineLabelColor = UIColor.white
		scrollableGraphView.topMargin = 15.0
		scrollableGraphView.bottomMargin = 10.0
		scrollableGraphView.dataPointSpacing = 5
		scrollableGraphView.direction = .rightToLeft
		scrollableGraphView.rightmostPointPadding = 0
		scrollableGraphView.leftmostPointPadding = 0
		scrollableGraphView.shouldAnimateOnStartup = false
		scrollableGraphView.shouldAutomaticallyDetectRange = true
		scrollableGraphView.shouldRangeAlwaysStartAtZero = false
		scrollableGraphView.shouldAdaptRange = true
		scrollableGraphView.lineStyle = ScrollableGraphViewLineStyle.smooth
		scrollableGraphView.shouldDrawDataPoint = false
		scrollableGraphView.adaptAnimationType = ScrollableGraphViewAnimationType.elastic

		// dateFormaterを定義
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "H:m" // 日付フォーマットの設定

		// 取得したデータをデータ配列に設定
		let dataEntry = self.pressureValue*10
		let dateObj = dateFormatter.string(from: Date())	// 日付文字列を得る

		data.append(dataEntry)
		labels.append(dateObj)

		// viewにチャートデータを設定
		scrollableGraphView.set(data: data, withLabels: labels)
	}

// MARK: - Time
	func getTime() {
		let formatter = DateFormatter()
		formatter.dateFormat = "EEE MM/dd/yyyy HH:mm:ss" //表示形式を設定

		//現在時刻
		let now = Date(timeIntervalSinceNow: 0) //"Dec 13, 2016, 4:10 PM"

		//現在時刻を文字列で取得
		let nowString = formatter.string(from: now) //"2016/12/13 16:10:31"
		self.timeLabel.text = String(nowString)
	}
	

// MARK: - ステータスバーを隠す
	override var prefersStatusBarHidden : Bool {
		return true
	}

// MARK: - didReceiveMemoryWarning
	override func didReceiveMemoryWarning() {
	super.didReceiveMemoryWarning()
	// Dispose of any resources that can be recreated.
	}

// classとじかっこ
}
