//
//  ViewController.swift
//  tableViewTest
//
//  Created by Shawn Chun on 20/06/2019.
//  Copyright © 2019 shawn. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ViewController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	
	let disposeBag = DisposeBag()
	
	func bindTableView() {
		let cities = Observable.of(["Lisbon", "Copenhagen", "Lodon", "Madrid", "Vienna"])
		cities.bind(to: tableView.rx.items) { (tableView: UITableView, index: Int, element: String) in
			let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
			cell.textLabel?.text = element
			return cell
		}
		.disposed(by: disposeBag)
		
		tableView.rx
			.modelSelected(String.self)
			.subscribe(onNext: { model in
				print("\(model) was selected")
			})
			.disposed(by: disposeBag)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		bindTableView()
	}

	override func didReceiveMemoryWarning() {
	}
}

