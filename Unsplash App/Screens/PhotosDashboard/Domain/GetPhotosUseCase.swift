//
//  GetPhotosUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol GetPhotosUseCaseType {
    func execute(page: Int) -> Observable<Result<[Photo], PhotoError>>
}

struct GetPhotosUseCase: GetPhotosUseCaseType {
    private let photosRepository: PhotosRepositoryType
    
    init(photosRepository: PhotosRepositoryType = PhotosRepository()) {
        self.photosRepository = photosRepository
    }
    
    func execute(page: Int) -> Observable<Result<[Photo], PhotoError>> {
        photosRepository.getPhotos(page: page)
    }
}
