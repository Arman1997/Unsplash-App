//
//  GetAllFavoritesUseCases.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 31.05.24.
//

import Foundation
import RxSwift

protocol GetAllFavoritesUseCasesType {
    func execute() -> Observable<[SavedPhotoImage]>
}

struct GetAllFavoritesUseCases: GetAllFavoritesUseCasesType {
    private let photosManager: PhotoManager = PhotoManager()
    
    func execute() -> Observable<[SavedPhotoImage]> {
        return photosManager.getAllPhotos()
    }
}
