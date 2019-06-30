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

import Foundation
import RxSwift

fileprivate var internalCache = [String: Data]()

public enum RxURLSessionError: Error {
	case unknown
	case invalidAPI(description: String)
	case invalidResponse(response: URLResponse)
	case requestFailed(response: HTTPURLResponse, data: Data?)
	case deserializationFailed
}

extension Reactive where Base: URLSession {
	func response(request: URLRequest) -> Observable<(Result<(URLResponse, Data), Error>)> {
		return Observable.create { observer in
			let task = self.base.dataTask(with: request) { (data, response, error) in
				if let error = error {
					observer.onNext(.failure(error))
					return
				}
				guard let response = response, let data = data else {
					let error = NSError(domain: "error", code: 0, userInfo: nil)
					observer.onNext(.failure(error))
					return
				}
				observer.onNext(.success((response, data)))
				observer.onCompleted()
			}
			task.resume()
			return Disposables.create(with: task.cancel)
		}
	}
	
	func data(request: URLRequest) -> Observable<Data> {
		if let url = request.url?.absoluteString, let data = internalCache[url] {
			return Observable.just(data)
		}
		return response(request: request).cache().map { result -> Data in
			switch result {
			case .success(let (response, data)):
				guard let httpResponse = response as? HTTPURLResponse else {
					throw RxURLSessionError.invalidResponse(response: response)
				}
				guard 200..<300 ~= httpResponse.statusCode else {
					throw RxURLSessionError.requestFailed(response: httpResponse, data: data)
				}
				return data
			case .failure(let error):
				throw RxURLSessionError.invalidAPI(description: error.localizedDescription)
			}
		}
	}
	
	func string(request: URLRequest) -> Observable<String> {
		return data(request: request).map { data in
			return String(data: data, encoding: .utf8) ?? ""
		}
	}
	
	func json(request: URLRequest) -> Observable<Any> {
		return data(request: request).map { data in
			return try JSONSerialization.jsonObject(with: data)
		}
	}
	
	func decodable<T: Decodable>(request: URLRequest, type: T.Type) -> Observable<T> {
		return data(request: request).map { data in
			let decoder = JSONDecoder()
			return try decoder.decode(type, from: data)
		}
	}
	
	func image(request: URLRequest) -> Observable<UIImage> {
		return data(request: request).map { data in
			guard let image = UIImage(data: data) else {
				throw RxURLSessionError.deserializationFailed
			}
			return image
		}
	}
}

extension ObservableType where E == Result<(URLResponse, Data), Error> {
	func cache() -> Observable<E> {
		return self.do(onNext: { result in
			switch result {
			case .success(let (response, data)):
				guard let url = response.url?.absoluteString,
					let statusCode = (response as? HTTPURLResponse)?.statusCode,
					200..<300 ~= statusCode else {
						return
				}
				internalCache[url] = data
			case .failure( _): break
			}
		})
	}
}
