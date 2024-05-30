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
}

struct NetworkingService: NetworkingServiceType {
    func get(_ requestData: RequestData) -> Observable<ResponseData> {
        fatalError()
    }
}
