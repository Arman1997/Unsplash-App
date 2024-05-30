//
//  PhotosDashboardDescriptorMapper.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import UIKit
import RxSwift

protocol PhotosDashboardViewDescriptorMapperType {
    func map(_ photos: [Photo]) -> PhotosDashboardViewDescriptor
}

struct PhotosDashboardViewDescriptorMapper: PhotosDashboardViewDescriptorMapperType {
    private let networkServiceType: NetworkingServiceType = NetworkingService()
    
    func map(_ photos: [Photo]) -> PhotosDashboardViewDescriptor {
        PhotosDashboardViewDescriptor(
            images: photos.map(mapCellDescriptor)
        )
    }
    
    func mapCellDescriptor(fromPhoto photo: Photo) -> PhotoCellDescriptor {
        .init(
            imageChannel: networkServiceType.getImage(photo.url),
            imageHeight: photo.height,
            imageWidth: photo.width,
            imageId: photo.id
        )
    }
}
