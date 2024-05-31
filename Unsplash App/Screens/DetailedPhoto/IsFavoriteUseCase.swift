//
//  IsFavoriteUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol IsFavoriteUseCaseType {
    func execute(_ photoId: String) -> Observable<Bool>
}

struct IsFavoriteUseCase: IsFavoriteUseCaseType {
    private let photosManager = PhotoManager()
    func execute(_ photoId: String) -> Observable<Bool> {
        return photosManager.imageExists(photoId: photoId)
    }
}

class PhotoManager {
    private let disposeBag = DisposeBag()
    private let fileManager = FileManager.default

    private var imagesDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Images")
    }
    
    init() {
        createImagesDirectory()
    }
    
    private func createImagesDirectory() {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create images directory: \(error)")
            }
        }
    }

    // Method to save UIImage to file system
    func saveImage(photoId: String, image: UIImage) -> Observable<Bool> {
        return Observable<Bool>.create { observer in
            let fileURL = self.imagesDirectory.appendingPathComponent("\(photoId).png")
            
            if let imageData = image.pngData() {
                do {
                    try imageData.write(to: fileURL)
                    observer.onNext(true)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            } else {
                observer.onError("Failed to convert UIImage to PNG data")
            }
            
            return Disposables.create()
        }
    }

    func removeImage(photoId: String) -> Observable<Bool> {
        return Observable<Bool>.create { observer in
            let fileURL = self.imagesDirectory.appendingPathComponent("\(photoId).png")
            
            do {
                if self.fileManager.fileExists(atPath: fileURL.path) {
                    try self.fileManager.removeItem(at: fileURL)
                    observer.onNext(true)
                } else {
                    observer.onNext(false)
                }
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }

    func imageExists(photoId: String) -> Observable<Bool> {
        return Observable<Bool>.create { observer in
            let fileURL = self.imagesDirectory.appendingPathComponent("\(photoId).png")
            let exists = self.fileManager.fileExists(atPath: fileURL.path)
            observer.onNext(exists)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
