//
//  GetBigSizedPhotoUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol GetBigSizedPhotoUseCaseType {
    func execute(_ photoId: String) -> Observable<Result<UIImage, DetailedPhotoError>>
}

struct GetBigSizedPhotoUseCase: GetBigSizedPhotoUseCaseType {
    func execute(_ photoId: String) -> Observable<Result<UIImage, DetailedPhotoError>> {
        .create { observer in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                observer.onNext(.success(UIImage.image0))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
