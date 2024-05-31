//
//  FavoritesViewModel.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 31.05.24.
//

import Foundation
import RxSwift

struct FavoritesViewModel {
    enum ViewState {
        case loading(Bool)
        case loaded(FavoritesDescriptor)
    }
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let viewDidAppear: Observable<Void>
        let imageWithIndexSelected: Observable<Int>
    }
    
    struct Output {
        let state: Observable<ViewState>
        let navigateToPhotoDetails: Observable<Photo>
    }
    
    struct UseCases {
        let getAllFavorites: GetAllFavoritesUseCasesType
    }
    
    private let useCases: UseCases
    
    init(useCases: UseCases) {
        self.useCases = useCases
    }
    
    func transform(_ input: Input) -> Output {
        let requestTriggers = Observable.merge(input.viewDidLoad, input.viewDidAppear)
        let savedPhotos = requestTriggers
            .debounce(RxTimeInterval.seconds(1), scheduler: MainScheduler.asyncInstance)
            .flatMap(useCases.getAllFavorites.execute)

        let descriptor = savedPhotos.map { $0.map { $0.image } }.map(FavoritesDescriptor.init)
        let loadedState = descriptor.map(ViewState.loaded)
        let loadingState = Observable.merge(
            requestTriggers.mapTo(true),
            savedPhotos.mapTo(false)
        ).map(ViewState.loading)
        
        let state = Observable.merge(loadingState, loadedState)
        
        let navigateToPhotoDetails = input.imageWithIndexSelected.withLatestFrom(savedPhotos) { $1[$0] }.map(\.photo)
        return Output(
            state: state,
            navigateToPhotoDetails: navigateToPhotoDetails
        )
    }
}
