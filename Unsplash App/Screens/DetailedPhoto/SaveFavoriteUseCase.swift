//
//  SaveFavoriteUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol SaveFavoriteUseCaseType {
    func execute(_ photo: Photo, _ image: UIImage) -> Observable<Bool>
}

struct SaveFavoriteUseCase: SaveFavoriteUseCaseType {
    private let photoManager: PhotoManager = PhotoManager()
    
    func execute(_ photo: Photo, _ image: UIImage) -> Observable<Bool> {
        photoManager.savePhoto(photo, image: image)
    }
}
