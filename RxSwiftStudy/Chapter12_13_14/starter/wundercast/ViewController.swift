/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

class ViewController: UIViewController {
	@IBOutlet private var searchCityName: UITextField!
	@IBOutlet private var tempLabel: UILabel!
	@IBOutlet private var humidityLabel: UILabel!
	@IBOutlet private var iconLabel: UILabel!
	@IBOutlet private var cityNameLabel: UILabel!
	@IBOutlet private var geoLocationButton: UIButton!
	@IBOutlet private var mapView: MKMapView!
	@IBOutlet private var mapButton: UIButton!
	
	@IBOutlet private var tempSwitch: UISwitch!
	@IBOutlet private var activityIndicator: UIActivityIndicatorView!
	
	let locationManager = CLLocationManager()
	
	var disposeBag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		style()
		
		let currentLocation = locationManager.rx.didUpdateLocations
			.map { $0[0] }
			.filter { $0.horizontalAccuracy < kCLLocationAccuracyHundredMeters }
		
		let geoInput = geoLocationButton.rx.tap.asObservable()
			.do(onNext: { [weak self] _ in
				self?.locationManager.requestWhenInUseAuthorization()
				self?.locationManager.startUpdatingLocation()
			})
		
		let geoLocation = geoInput.flatMap {
			return currentLocation.take(1)
		}
		
		let geoSearch = geoLocation.flatMap { location in
			return ApiController.shared.currentWeather(at: location.coordinate)
				.catchErrorJustReturn(.dummy)
		}
		
		let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit)
			.map { self.searchCityName.text ?? "" }
			.filter { !$0.isEmpty }
		
		let textSearch = searchInput.debug().flatMap { text in
			return ApiController.shared.currentWeather(city: text)
				.catchErrorJustReturn(.dummy)
		}
		
		let mapInput = mapView.rx.regionDidChangeAnimated
			.skip(1)
			.map { [unowned self] _ in self.mapView.centerCoordinate }
		
		let mapSearch = mapInput.flatMap { coordinate in
			return ApiController.shared.currentWeather(at: coordinate)
				.catchErrorJustReturn(.dummy)
		}
		
		let tempTypeInput = tempSwitch.rx.controlEvent(.valueChanged)
			.map { self.cityNameLabel.text ?? "" }
			.filter { !$0.isEmpty }
		
		let tempSwitchSearch = tempTypeInput.flatMap { text in
			return ApiController.shared.currentWeather(city: text)
				.catchErrorJustReturn(.dummy)
		}
		
		let search = Observable.of(textSearch, geoSearch, tempSwitchSearch, mapSearch).merge()
			.asDriver(onErrorJustReturn: ApiController.Weather.dummy)
		
		let running = Observable.from([
			searchInput.map { _ in true },
			geoInput.map { _ in true },
			mapInput.map { _ in true },
			tempTypeInput.map  { _ in true },
			search.map { _ in false }.asObservable()
			])
			.merge()
			.startWith(true)
			.asDriver(onErrorJustReturn: false)
		
		running
			.skip(1)
			.drive(activityIndicator.rx.isAnimating)
			.disposed(by: disposeBag)
		
		running
			.drive(tempLabel.rx.isHidden)
			.disposed(by: disposeBag)
		
		running
			.drive(iconLabel.rx.isHidden)
			.disposed(by: disposeBag)
		
		running
			.drive(humidityLabel.rx.isHidden)
			.disposed(by: disposeBag)
		
		running
			.drive(cityNameLabel.rx.isHidden)
			.disposed(by: disposeBag)
		
		running
			.drive(tempSwitch.rx.isHidden)
			.disposed(by: disposeBag)
		
		search.map {
			return self.tempSwitch.isOn ? "\($0.temperature)° C" : "\(Double($0.temperature) * 1.8 + 32)° F"
			}
			.drive(tempLabel.rx.text)
			.disposed(by: disposeBag)
		
		search.map { $0.icon }
			.drive(iconLabel.rx.text)
			.disposed(by: disposeBag)
		
		search.map { "\($0.humidity)%" }
			.drive(humidityLabel.rx.text)
			.disposed(by: disposeBag)
		
		search.map { $0.cityName }
			.drive(cityNameLabel.rx.text)
			.disposed(by: disposeBag)
		
		search.map { [$0.overlay()] }
			.drive(mapView.rx.overlays)
			.disposed(by: disposeBag)
		
		mapButton.rx.tap
			.subscribe(onNext: {
				self.mapView.isHidden.toggle()
			})
			.disposed(by: disposeBag)
		
		mapView.rx.setDelegate(self)
			.disposed(by: disposeBag)
		
		textSearch.asDriver(onErrorJustReturn: .dummy)
			.map { $0.coordinate }
			.drive(mapView.rx.location)
			.disposed(by: disposeBag)
		
		mapInput.debug().flatMap { coordinate in
			return ApiController.shared.currentWeatherAround(location: coordinate)
				.catchErrorJustReturn([])
			}
			.asDriver(onErrorJustReturn: [])
			.map { $0.map { $0.overlay() } }
			.drive(mapView.rx.overlays)
			.disposed(by: disposeBag)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		Appearance.applyBottomLine(to: searchCityName)
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Style
	
	private func style() {
		view.backgroundColor = UIColor.aztec
		searchCityName.textColor = UIColor.ufoGreen
		tempLabel.textColor = UIColor.cream
		humidityLabel.textColor = UIColor.cream
		iconLabel.textColor = UIColor.cream
		cityNameLabel.textColor = UIColor.cream
	}
}

extension ViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if let overlay = overlay as? ApiController.Weather.Overlay {
			let overlayView = ApiController.Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
			return overlayView
		}
		return MKOverlayRenderer()
	}
}