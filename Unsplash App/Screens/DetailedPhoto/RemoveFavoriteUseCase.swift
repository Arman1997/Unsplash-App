//
//  RemoveFavoriteUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol RemoveFavoriteUseCaseType {
    func execute(_ photoId: String) -> Observable<Bool>
}

struct RemoveFavoriteUseCase: RemoveFavoriteUseCaseType {
    private let photoManager: PhotoManager = PhotoManager()
    
    func execute(_ photoId: String) -> Observable<Bool> {
        photoManager.removeImage(photoId: photoId)
    }
}
