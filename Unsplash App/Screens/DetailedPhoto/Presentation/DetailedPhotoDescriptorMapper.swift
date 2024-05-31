//
//  DetailedPhotoDescriptorMapper.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import UIKit

protocol DetailedPhotoDescriptorMapperType {
    func map(_ photo: Photo, _ bigSizedImage: UIImage, isFavorite: Bool) -> DetailedPhotoDescriptor
}

struct DetailedPhotoDescriptorMapper: DetailedPhotoDescriptorMapperType {
    func map(_ photo: Photo, _ bigSizedImage: UIImage, isFavorite: Bool) -> DetailedPhotoDescriptor {
        return DetailedPhotoDescriptor(
            authorName: photo.authorName,
            dateCreated: photo.createdAt,
            description: photo.description,
            image: bigSizedImage,
            isFavorite: isFavorite
        )
    }
}
