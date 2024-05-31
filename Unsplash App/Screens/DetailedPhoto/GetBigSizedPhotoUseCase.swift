//
//  GetBigSizedPhotoUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol GetBigSizedPhotoUseCaseType {
    func execute(_ url: URL) -> Observable<Result<UIImage, DetailedPhotoError>>
}

struct GetBigSizedPhotoUseCase: GetBigSizedPhotoUseCaseType {
    private let networkService: NetworkingServiceType = NetworkingService()
    
    func execute(_ url: URL) -> Observable<Result<UIImage, DetailedPhotoError>> {
        networkService.getImage(url).map { Result.success($0) }
    }
}
