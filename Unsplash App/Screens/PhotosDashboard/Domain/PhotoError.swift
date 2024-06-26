//
//  PhotoError.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation


enum PhotoError: Error {
    case invalidResponse
    case with(Error)
}
