import Foundation
import RxSwift
import RxCocoa

example(of: "PublishSubject") {
	let subject = PublishSubject<String>()
	
	subject.onNext("Is anyone listening?")
	
	let subscriptionOne = subject.subscribe(onNext: { string in
		print(string)
	})
	
	subject.on(.next("1"))
	
	subject.onNext("2")
	
	let subscriptionTwo = subject
		.subscribe { event in
			print("2)", event.element ?? event)
	}
	
	subject.onNext("3")
	
	subscriptionOne.dispose()
	
	subject.onNext("4")
	
	subject.onCompleted()
	
	subject.onNext("5")
	
	subscriptionTwo.dispose()
	
	let disposeBag = DisposeBag()
	
	subject.subscribe {
		print("3)", $0.element ?? $0)
	}
	.disposed(by: disposeBag)
	
	subject.onNext("?")
}

enum MyError: Error {
	case anError
}

func print<T: CustomStringConvertible>(label: String, event: Event<T>) {
	print(label, (event.element ?? event.error) ?? event)
}

example(of: "BehaviorSubject") {
	let subject = BehaviorSubject(value: "Initial value")
	let disposeBag = DisposeBag()
	
	subject.onNext("X")
	
	subject.subscribe {
		print(label: "1)", event: $0)
	}.disposed(by: disposeBag)
	
	subject.onError(MyError.anError)
	
	subject.subscribe {
		print(label: "2)", event: $0)
	}.disposed(by: disposeBag)
}

example(of: "ReplaySubject") {
	let subject = ReplaySubject<String>.create(bufferSize: 2)
	
	let disposeBag = DisposeBag()
	
	subject.onNext("1")
	subject.onNext("2")
	subject.onNext("3")
	
	subject.subscribe {
		print(label: "1)", event: $0)
		}.disposed(by: disposeBag)
	
	subject.subscribe {
		print(label: "2)", event: $0)
		}.disposed(by: disposeBag)
	
	subject.onNext("4")
	
	subject.onError(MyError.anError)
	
	subject.dispose()
	
	subject.subscribe {
		print(label: "3)", event: $0)
		}.disposed(by: disposeBag)
	
}

example(of: "BehaviorRelay") {
	let variable = BehaviorRelay(value: "Initial value")
	let disposeBag = DisposeBag()
	
	variable.accept("New initial value")
	
	variable.asObservable()
		.subscribe {
			print(label: "1)", event: $0)
	}.disposed(by: disposeBag)
	
	variable.accept("1")
	
	variable.asObservable()
		.subscribe {
			print(label: "2)", event: $0)
	}.disposed(by: disposeBag)
	
	variable.accept("2")
	
	print(variable.value)
}

/*:
 Copyright (c) 2019 Razeware LLC

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 distribute, sublicense, create a derivative work, and/or sell copies of the
 Software in any work that is designed, intended, or marketed for pedagogical or
 instructional purposes related to programming, coding, application development,
 or information technology.  Permission for such use, copying, modification,
 merger, publication, distribution, sublicensing, creation of derivative works,
 or sale is expressly withheld.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */
