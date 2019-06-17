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

class MainViewController: UIViewController {
	
	private let bag = DisposeBag()
	private let images = BehaviorRelay<[UIImage]>(value: [])
	private var imageCache = [Int]()
	
	@IBOutlet weak var imagePreview: UIImageView!
	@IBOutlet weak var buttonClear: UIButton!
	@IBOutlet weak var buttonSave: UIButton!
	@IBOutlet weak var itemAdd: UIBarButtonItem!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let writeImage = images.asObservable().share()
		
		writeImage.throttle(0.5, scheduler: MainScheduler())
			.subscribe(onNext: { [weak self] photos in
			guard let preview = self?.imagePreview else { return }
			preview.image = photos.collage(size: preview.frame.size)
		}).disposed(by: bag)
		
		writeImage.map {
			$0.count > 0 && $0.count % 2 == 0 ? true : false
			}.bind(to: buttonSave.rx.isEnabled)
			.disposed(by: bag)
		
		writeImage.map {
			$0.count > 0 ? true : false
			}.bind(to: buttonClear.rx.isEnabled)
			.disposed(by: bag)
		
		writeImage.map {
			$0.count < 6 ? true : false
			}.bind(to: itemAdd.rx.isEnabled)
			.disposed(by: bag)
		
		writeImage.map {
			$0.count > 0 ? "\($0.count) photos" : "Collage"
			}.bind(to: self.rx.title)
			.disposed(by: bag)
	}
	
	@IBAction func actionClear() {
		images.accept([])
		imageCache = []
	}
	
	@IBAction func actionSave() {
		guard let image = imagePreview.image else { return }
		PhotoWriter.save(image)
			.subscribe(onSuccess: { [weak self] id in
				self?.showMessage("Saved with id: \(id)")
				self?.actionClear()
			}, onError: { [weak self] error in
				self?.showMessage("Error", description: error.localizedDescription)
		}).disposed(by: bag)
	}
	
	@IBAction func actionAdd() {
		let photosViewController = storyboard!.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
		let newPhotos = photosViewController.selectedPhotos.share()
		newPhotos
			.takeWhile { [weak self] image in
				return (self?.images.value.count ?? 0) < 6
			}
			.filter {
				$0.size.width > $0.size.height
			}
			.filter { [weak self] newImage in
				let len = UIImagePNGRepresentation(newImage)?.count ?? 0
				guard self?.imageCache.contains(len) == false else {
					return false
				}
				self?.imageCache.append(len)
				return true
			}
			.subscribe(onNext: { [weak self] newImage in
			guard let images = self?.images else { return }
			images.accept(images.value + [newImage])
//			self?.navigationController!.popToRootViewController(animated: true)
			}, onDisposed: {
				print("completed photo selection")
		}).disposed(by: bag)
		
		newPhotos.ignoreElements().subscribe(onCompleted: { [weak self] in
			self?.updateNavigationIcon()
		}).disposed(by: bag)
		
		navigationController!.pushViewController(photosViewController, animated: true)
	}
	
	private func updateNavigationIcon() {
		let icon = imagePreview.image?
			.scaled(CGSize(width: 22, height: 22))
			.withRenderingMode(.alwaysOriginal)
		navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
	}
	
	func showMessage(_ title: String, description: String? = nil) {
		alert(title, description)
			.subscribe()
			.disposed(by: bag)
	}
}
