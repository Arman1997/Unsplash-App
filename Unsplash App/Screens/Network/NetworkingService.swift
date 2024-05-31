//
//  NetworkingService.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol NetworkingServiceType {
    func get(_ requestData: RequestData) -> Observable<ResponseData>
    func getImage(_ url: URL) -> Observable<UIImage>
}

struct NetworkingService: NetworkingServiceType {
    private let session = URLSession.shared
    
    func getImage(_ url: URL) -> Observable<UIImage> {
        return Observable<UIImage>.create { observer in
            session.dataTask(with: URLRequest(url: url)) { data, response, error in
                guard let data = data, let image = UIImage(data: data) else {
                    observer.onError("no image found")
                    observer.onCompleted()
                    return
                }
                
                observer.onNext(image)
                observer.onCompleted()
            }.resume()
            
            return Disposables.create()
        }
    }
    
    
    func get(_ requestData: RequestData) -> Observable<ResponseData> {
        guard var urlComponents = URLComponents(string: requestData.urlString) else {
            return Observable<ResponseData>.just(.failure("Invalid url components"))
        }
        
        urlComponents.queryItems = requestData.queryItems
        
        guard let url = urlComponents.url else {
            return Observable<ResponseData>.just(.failure("Invalid url"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return Observable<ResponseData>.create { [weak session] observer in
            guard let session = session else {
                observer.onCompleted()
                return Disposables.create()
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    observer.onNext(.failure(error))
                    observer.onCompleted()
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    observer.onNext(.failure("Server Error"))
                    observer.onCompleted()
                    return
                }

                guard let data = data else {
                    observer.onNext(.failure("Invalid response data"))
                    observer.onCompleted()
                    return
                }
                
                observer.onNext(.success(data))
                observer.onCompleted()
            }

            task.resume()
            
            return Disposables.create()
        }
    }
}

extension String: Error {}
