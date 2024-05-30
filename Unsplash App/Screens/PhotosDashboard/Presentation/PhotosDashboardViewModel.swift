//
//  PhotosDashboardViewModel.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

struct PhotosDashboardViewModel {
    enum ViewState {
        case loading
        case loaded(PhotosDashboardViewDescriptor)
        case nextPage(PhotosDashboardViewDescriptor)
        case error(PhotoError)
    }
    
    struct Constants {
        static let initialPage: Int = 1
        static let maxPageCount: Int = 10
    }
    
    struct Input {
        let viewDidLoaded: Observable<Void>
        let searchText: Observable<String>
        let selectedImageIndex: Observable<Int>
        let pulledToRefresh: Observable<Void>
        let nextPageRequested: Observable<Void>
    }
    
    struct Output {
        let state: Observable<ViewState>
        let navigateToPhotoDetails: Observable<Photo>
        let actions: Observable<Void>
    }
    
    struct Mappers {
        let descriptor: PhotosDashboardViewDescriptorMapperType
    }
    
    struct UseCases {
        let getPhotos: GetPhotosUseCaseType
    }
    
    private let mappers: Mappers
    private let useCases: UseCases
    
    
    init(
        mappers: Mappers = Mappers(descriptor: PhotosDashboardViewDescriptorMapper()),
        useCases: UseCases = UseCases(getPhotos: GetPhotosUseCase())
    ) {
        self.mappers = mappers
        self.useCases = useCases
    }
    
    func transform(input: Input) -> Output {
        
        let pageIndex = BehaviorSubject(value: Constants.initialPage)
        let loadFirstPageOnPull = input
            .pulledToRefresh
            .map { Constants.initialPage }
            .do(onNext: pageIndex.onNext)
        
        let loadNextPage = input
            .nextPageRequested
            .withLatestFrom(pageIndex)
            .map { $0 + 1 }
            .do(onNext: pageIndex.onNext)
        
        let page = pageIndex
            .distinctUntilChanged()
            .filter { $0 <= Constants.maxPageCount }
        
        let descriptorRequest = page.flatMapFirst { value in
            return useCases.getPhotos.execute(page: value)
        }
        .share()
        
        let descriptor = descriptorRequest
        .flatMap { result in
            switch result {
            case .success(let photos):
                return Observable.of(mappers.descriptor.map(photos))
            case .failure:
                return Observable.empty()
            }
        }
        
        let error: Observable<PhotoError?> = descriptorRequest
            .map { result in
                switch result {
                case .success:
                    return nil
                case .failure(let error):
                    return error
                }
            }
        
        let loading = Observable<Bool>.merge(
            input.viewDidLoaded.map { _ in true },
            loadFirstPageOnPull.map { _ in true },
            input.nextPageRequested.map { _ in true },
            descriptorRequest.map { _ in false },
            error.filter { $0 != nil } .map { _ in false }
        )
        
        let descriptorState = descriptor.map { ViewState.loaded($0) }
        let loadingState = loading.map { _ in ViewState.loading }
        let errorState = error
            .filter { $0 != nil }
            .map { ViewState.error($0!) }
        
        let state = Observable.merge(descriptorState, loadingState, errorState)
        
        return Output(
            state: state,
            navigateToPhotoDetails: Observable<Photo>.empty(),
            actions: Observable.merge([
                loadFirstPageOnPull.map { _ in return },
                loadNextPage.map { _ in return }
            ])
        )
    }
}
