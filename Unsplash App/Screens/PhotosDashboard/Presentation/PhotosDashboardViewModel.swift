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
        case loading(Bool)
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
        let searchButtonTapped: Observable<Void>
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
        let photos = BehaviorSubject(value: [Photo]())
        
        let loadFirstPageOnPull = input
            .pulledToRefresh
            .map { Constants.initialPage }
            .debug()
            .do(onNext: pageIndex.onNext)
        
        let loadNextPage = input
            .nextPageRequested
            .debounce(RxTimeInterval.seconds(2), scheduler: MainScheduler.asyncInstance)
            .withLatestFrom(pageIndex)
            
            .map { $0 + 1 }
            .do(onNext: pageIndex.onNext)
        
        let searchText = input.searchText.startWith("")
        
        let photosResponse = Observable.merge(
            pageIndex.withLatestFrom(searchText) { ($0,$1) },
            input.searchButtonTapped.withLatestFrom(pageIndex).withLatestFrom(searchText) { ($0,$1) }
        )
            .flatMapFirst(useCases.getPhotos.execute).share()
            .debug()
        
        let photosSuccess = photosResponse.flatMap { result in
            switch result {
            case .success(let photos):
                return Observable.of(photos)
            case .failure:
                return Observable.empty()
            }
        }
        
        let photosFailure = photosResponse.flatMap { result in
            switch result {
            case .failure(let error):
                return Observable.of(error)
            case .success:
                return Observable.empty()
            }
        }
        
        let firstPagePhotos = photosSuccess
            .withLatestFrom(pageIndex) { ($0,$1) }
            .filter { $0.1 == Constants.initialPage }
            .map { $0.0 }
            .do(onNext: {
                photos.onNext($0)
            })

        let nextPagePhotos = photosSuccess
            .withLatestFrom(pageIndex) { ($0,$1) }
            .filter { $0.1 > Constants.initialPage }
            .map { $0.0 }
            .withLatestFrom(photos) { ($0,$1) }
            .do(onNext: {
                photos.onNext($1 + $0)
            })
        
        let loading = Observable<Bool>.merge(
            input.viewDidLoaded.mapTo(true),
            loadFirstPageOnPull.mapTo(true),
            input.nextPageRequested.mapTo(true),
            photosResponse.mapTo(false),
            input.searchButtonTapped.mapTo(true)
        )
        
        let loadedState = photos
            .withLatestFrom(pageIndex, resultSelector: {($0,$1)})
            .filter { $0.1 == Constants.initialPage }
            .map { $0.0 }.map(mappers.descriptor.map)
            .map(ViewState.loaded)

        let nextPageState = photos
            .withLatestFrom(pageIndex, resultSelector: {($0,$1)})
            .filter { $0.1 > Constants.initialPage }
            .map { $0.0 }.map(mappers.descriptor.map)
            .map(ViewState.nextPage)
        
        let loadingState = loading.map(ViewState.loading)
        let errorState = photosFailure.map(ViewState.error)
        
        let state = Observable.merge(nextPageState, loadingState, errorState, loadedState)
        
        let navigateToPhotosDetails = input.selectedImageIndex.withLatestFrom(photosSuccess) { $1[$0] }
        
        return Output(
            state: state,
            navigateToPhotoDetails: navigateToPhotosDetails,
            actions: Observable.merge([
                loadFirstPageOnPull.mapToVoid(),
                loadNextPage.mapToVoid(),
                firstPagePhotos.mapToVoid(),
                nextPagePhotos.mapToVoid()
            ])
        )
    }
}

extension Observable {
    func mapTo<T>(_ value: T) -> Observable<T> {
        map { _ in return value }
    }
    
    func mapToVoid() -> Observable<Void> {
        mapTo(())
    }
}
