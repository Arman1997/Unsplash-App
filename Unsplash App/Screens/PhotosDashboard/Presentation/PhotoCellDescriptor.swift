//
//  PhotoCellDescriptor.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

struct PhotoCellDescriptor {
    let imageChannel: Observable<UIImage>
    let imageHeight: CGFloat
    let imageId: String
}
