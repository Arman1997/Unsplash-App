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
        Observable<Void>.create { observer in
            UserDefaults.standard.setValue(true, forKey: photoId)
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
