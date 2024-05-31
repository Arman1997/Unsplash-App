//
//  SaveFavoriteUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol SaveFavoriteUseCaseType {
    func execute(_ photoId: String) -> Observable<Void>
}

struct SaveFavoriteUseCase: SaveFavoriteUseCaseType {
    func execute(_ photoId: String) -> Observable<Void> {
        UserDefaults.standard.setValue(true, forKey: photoId)
        UserDefaults.standard.synchronize()
        return Observable.of(())
    }
}
