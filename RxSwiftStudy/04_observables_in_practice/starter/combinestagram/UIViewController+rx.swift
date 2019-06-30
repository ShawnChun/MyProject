//
//  UIViewController+rx.swift
//  Combinestagram
//
//  Created by Shawn Chun on 25/05/2019.
//  Copyright © 2019 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
	func alert(_ title: String, _ message: String? = nil) -> Completable {
		return Completable.create { [weak self] completable in
			let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
			alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
				completable(.completed)
			}))
			self?.present(alertVC, animated: true, completion: nil)
			return Disposables.create {
				self?.dismiss(animated: true, completion: nil)
			}
		}
	}
}
