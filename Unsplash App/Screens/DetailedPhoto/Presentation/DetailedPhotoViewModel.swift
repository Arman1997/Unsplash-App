//
//  DetailedPhotoViewModel.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

struct DetailedPhotoViewModel {
    enum ViewState {
        case loading(Bool)
        case loaded(DetailedPhotoDescriptor)
        case error(DetailedPhotoError)
    }
    
    struct Input {
        let viewDidLoaded: Observable<Void>
        let favoriteButtonTapped: Observable<Void>
    }
    
    struct Output {
        let state: Observable<ViewState>
        let actions: Observable<Void>
    }
    
    struct Mappers {
        let descriptor: DetailedPhotoDescriptorMapperType
    }

    struct UseCases {
        let isFavoriteUseCase: IsFavoriteUseCaseType
        let saveFavorite: SaveFavoriteUseCaseType
        let removeFavorite: RemoveFavoriteUseCaseType
        let getBigSizedPhoto: GetBigSizedPhotoUseCaseType
    }

    struct Configs {
        let photo: Photo
    }
    
    private let useCases: UseCases
    private let mappers: Mappers
    private let configs: Configs
    
    init(useCases: UseCases, mappers: Mappers, configs: Configs) {
        self.useCases = useCases
        self.mappers = mappers
        self.configs = configs
    }
    
    func transform(_ input: Input) -> Output {
        let getBigSizedPhotoResponse = input
            .viewDidLoaded
            .mapTo(configs.photo.urls.big)
            .flatMap(useCases.getBigSizedPhoto.execute)
            .share()
        
        
        let getBigSizedPhotoSuccess = getBigSizedPhotoResponse.flatMap { result in
            switch result {
            case .success(let image):
                return Observable.of(image)
            case .failure:
                return Observable.empty()
            }
        }.take(1)
        
        let getBigSizedPhotoFailure = getBigSizedPhotoResponse.flatMap { result in
            switch result {
            case .failure(let error):
                return Observable.of(error)
            case .success:
                return Observable.empty()
            }
        }
        
        let favoriteButtonTap = input.favoriteButtonTapped
        
        let saveFavorite = favoriteButtonTap
            .mapTo(configs.photo.id)
            .flatMap(useCases.isFavoriteUseCase.execute)
            .filter { !$0 }
            .mapTo(configs.photo.id)
            .flatMap(useCases.saveFavorite.execute)

        let removeFavorite = favoriteButtonTap
            .mapTo(configs.photo.id)
            .flatMap(useCases.isFavoriteUseCase.execute)
            .filter { $0 }
            .mapTo(configs.photo.id)
            .flatMap(useCases.removeFavorite.execute)
        
        let descriptor = Observable.merge(
            getBigSizedPhotoSuccess
            .withLatestFrom(useCases.isFavoriteUseCase.execute(configs.photo.id)) { ($0,$1) }
            .map { (configs.photo, $0.0, $0.1) }
            .map(mappers.descriptor.map),
            
            favoriteButtonTap.mapToVoid().withLatestFrom(getBigSizedPhotoSuccess)
            .withLatestFrom(useCases.isFavoriteUseCase.execute(configs.photo.id)) { ($0,$1) }
                .map { (configs.photo, $0.0, $0.1) }
                .map(mappers.descriptor.map)
        )
        
        let loadedState = descriptor.map(ViewState.loaded)
        let loadingState = Observable.merge(
            input.viewDidLoaded.mapTo(true),
            getBigSizedPhotoResponse.mapTo(false)
        ).map(ViewState.loading)
        let errorState = getBigSizedPhotoFailure.map(ViewState.error)
        
        let state = Observable.merge(
            loadingState,
            loadedState,
            errorState
        )
        

        
        
        return Output(
            state: state,
            actions: Observable<Void>.empty()
        )
    }
}
