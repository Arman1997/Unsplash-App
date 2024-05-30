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
    func execute(_ photoId: String) -> Observable<Bool> {
        Observable<Bool>.create { observer in
            let isFavorite: Bool = (UserDefaults.standard.value(forKey: photoId) as? Bool) ?? false
            observer.onNext(isFavorite)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
