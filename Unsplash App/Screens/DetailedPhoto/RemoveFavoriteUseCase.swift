//
//  RemoveFavoriteUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol RemoveFavoriteUseCaseType {
    func execute(_ photo: Photo) -> Observable<Bool>
}

struct RemoveFavoriteUseCase: RemoveFavoriteUseCaseType {
    private let photoManager: PhotoManager = PhotoManager()
    
    func execute(_ photo: Photo) -> Observable<Bool> {
        photoManager.removePhoto(photo)
    }
}
