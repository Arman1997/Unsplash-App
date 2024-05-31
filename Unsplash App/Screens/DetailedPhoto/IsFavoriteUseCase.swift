//
//  IsFavoriteUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol IsFavoriteUseCaseType {
    func execute(_ photoId: String) -> Observable<Bool>
}

struct IsFavoriteUseCase: IsFavoriteUseCaseType {
    func execute(_ photoId: String) -> Bool {
        let isFavorite = UserDefaults.standard.bool(forKey: photoId)
        return isFavorite
    }
}
