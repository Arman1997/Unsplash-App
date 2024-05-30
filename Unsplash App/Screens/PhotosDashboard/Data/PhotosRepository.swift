//
//  PhotosRepository.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol PhotosRepositoryType {
    func getPhotos(page: Int) -> Observable<Result<[Photo], PhotoError>>
}

struct PhotosRepository: PhotosRepositoryType {
    func getPhotos(page: Int) -> Observable<Result<[Photo], PhotoError>> {
        return .just(.success([]))
    }
}
