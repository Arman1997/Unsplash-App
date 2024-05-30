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
    func map(_ photos: [Photo]) -> PhotosDashboardViewDescriptor {
        PhotosDashboardViewDescriptor(
            images: mockphotos.enumerated().map { (index, mockPhoto) in
                PhotoCellDescriptor(
                    imageChannel: Observable<Int>.timer(RxTimeInterval.milliseconds( Int.random(in: 300...400) ), scheduler: SerialDispatchQueueScheduler(qos: .background)).map { _ in return mockPhoto }.startWith(UIImage.strokedCheckmark),
                    imageHeight: mockPhoto.size.height,
                    imageId: String(index)
                )
            }
        )
    }
}

private let mockphotos: [UIImage] = [
    UIImage.image0,
    UIImage.image1,
    UIImage.image2,
    UIImage.image3,
    UIImage.image4,
    UIImage.image0,
    UIImage.image1,
    UIImage.image2,
    UIImage.image3,
    UIImage.image4,
    UIImage.image0,
    UIImage.image1,
    UIImage.image2,
    UIImage.image3,
    UIImage.image4,
    UIImage.image0,
    UIImage.image1,
    UIImage.image2,
    UIImage.image3,
    UIImage.image4,
    UIImage.image0,
    UIImage.image1,
    UIImage.image2,
    UIImage.image3,
    UIImage.image4,
    UIImage.image0,
    UIImage.image1,
    UIImage.image2,
    UIImage.image3,
    UIImage.image4,
]
