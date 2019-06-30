//
//  PushedEditTaskViewModel.swift
//  QuickTodo
//
//  Created by Shawn Chun on 30/06/2019.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct PushedEditTaskViewModel {
	
	let itemTitle: String
	let onUpdate: Action<String, Void>
	let disposeBag = DisposeBag()
	
	init(task: TaskItem, coordinator: SceneCoordinatorType, updateAction: Action<String, Void>) {
		itemTitle = task.title
		onUpdate = updateAction
	}
}
