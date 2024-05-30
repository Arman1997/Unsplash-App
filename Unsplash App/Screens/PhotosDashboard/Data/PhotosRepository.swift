//
//  PhotosRepository.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

struct GetPhotoDTO: Decodable {
    
    
    struct User: Decodable {
        let name: String
    }
    
    struct Urls: Decodable {
        let raw: URL
        let small: URL
        let regular: URL
        let thumb: URL
    }
    
    let id: String
    let created_at: String
    let height: Int
    let width: Int
    let description: String?
    let user: User
    let urls: Urls
}

struct SearchPhotoDTO: Decodable {
    let results: [GetPhotoDTO]
}

protocol PhotosRepositoryType {
    func getPhotos(page: Int,searchText: String) -> Observable<Result<[Photo], PhotoError>>
}

struct PhotosRepository: PhotosRepositoryType {
    private let networkService: NetworkingServiceType
    private let decoder: JSONDecoder
    
    init(networkService: NetworkingServiceType = NetworkingService(), 
         decoder: JSONDecoder = JSONDecoder()) {
        self.networkService = networkService
        self.decoder = decoder
    }
    
    func getPhotos(page: Int, searchText: String) -> Observable<Result<[Photo], PhotoError>> {
        var url = searchText.isEmpty ? "https://api.unsplash.com/photos/" : "https://api.unsplash.com/search/photos/"
        var queryItems = [
            URLQueryItem(name: "client_id", value: "EvILfIMijnKKj240kEwvZBrFPvdI9LR4Mc2LtdtlIH4"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: "20"),
        ]
        
        if !searchText.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: searchText))
        }
        
        let requestData = RequestData(
            urlString: url,
            queryItems: queryItems
        )
        
        return networkService.get(requestData).flatMap { responseData in
            switch responseData {
            case .success(let data):
                do {
                    var photos: [GetPhotoDTO]
                    if searchText.isEmpty {
                        photos = try decoder.decode([GetPhotoDTO].self, from: data)
                    } else {
                        let searchPhotos = try decoder.decode(SearchPhotoDTO.self, from: data)
                        photos = searchPhotos.results
                    }
                    
                    
                    return Observable<Result<[Photo], PhotoError>>.just(.success(photos.map { $0.toDomain() } ))
                } catch let jsonDecodingError {
                    print(jsonDecodingError)
                    return Observable<Result<[Photo], PhotoError>>.just(.failure(PhotoError.invalidResponse))
                }
            case .failure(let error):
                return Observable<Result<[Photo], PhotoError>>.just(.failure(PhotoError.with(error)))
            }
        }
    }
}

extension GetPhotoDTO {
    func toDomain() -> Photo {
        .init(
            id: id,
            url: urls.thumb,
            authorName: user.name,
            createdAt: created_at,
            description: description ?? "",
            height: CGFloat(height),
            width: CGFloat(width)
        )
    }
}
