//
//  RemoveFavoriteUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol RemoveFavoriteUseCaseType {
    func execute(_ photoId: String) -> Observable<Void>
}

struct RemoveFavoriteUseCase: RemoveFavoriteUseCaseType {
    func execute(_ photoId: String) -> Observable<Void> {
        UserDefaults.standard.setValue(false, forKey: photoId)
        UserDefaults.standard.synchronize()
        return Observable.of(())
    }
}
