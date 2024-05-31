//
//  IsFavoriteUseCase.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import RxSwift

protocol IsFavoriteUseCaseType {
    func execute(_ photo: Photo) -> Observable<Bool>
}

struct IsFavoriteUseCase: IsFavoriteUseCaseType {
    private let photosManager = PhotoManager()
    func execute(_ photo: Photo) -> Observable<Bool> {
        return photosManager.photoExists(photo)
    }
}

struct SavedPhotoImage {
    let photo: Photo
    let image: UIImage
}


struct PhotoManager {
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

    func savePhoto(_ photo: Photo, image: UIImage) -> Observable<Bool> {
        return Observable<Bool>.create { observer in
            let photoDirectory = self.imagesDirectory.appendingPathComponent(photo.id)
            
            do {
                try self.fileManager.createDirectory(at: photoDirectory, withIntermediateDirectories: true, attributes: nil)
                let photoData = try JSONEncoder().encode(photo)
                let photoFileURL = photoDirectory.appendingPathComponent("photo.json")
                try photoData.write(to: photoFileURL)
                
                let imageData = image.pngData()
                let imageFileURL = photoDirectory.appendingPathComponent("image.png")
                try imageData?.write(to: imageFileURL)
                
                observer.onNext(true)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }

    func removePhoto(_ photo: Photo) -> Observable<Bool> {
        return Observable<Bool>.create { observer in
            let photoDirectory = self.imagesDirectory.appendingPathComponent(photo.id)
            let fileURL = photoDirectory.appendingPathComponent("image.png")
            
            do {
                if self.fileManager.fileExists(atPath: fileURL.path) {
                    try self.fileManager.removeItem(at: fileURL)
                    
                    let photoFileURL = photoDirectory.appendingPathComponent("photo.json")
                    if self.fileManager.fileExists(atPath: photoFileURL.path) {
                        try self.fileManager.removeItem(at: photoFileURL)
                    }
                    
                    if let contents = try? self.fileManager.contentsOfDirectory(atPath: photoDirectory.path), contents.isEmpty {
                        try self.fileManager.removeItem(at: photoDirectory)
                    }
                    
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

    func photoExists(_ photo: Photo) -> Observable<Bool> {
        return Observable<Bool>.create { observer in
            let photoDirectory = self.imagesDirectory.appendingPathComponent(photo.id)
            let fileURL = photoDirectory.appendingPathComponent("image.png")
            let exists = self.fileManager.fileExists(atPath: fileURL.path)
            observer.onNext(exists)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }

    func getAllPhotos() -> Observable<[SavedPhotoImage]> {
        return Observable<[SavedPhotoImage]>.create { observer in
            do {
                let subdirectories = try self.fileManager.contentsOfDirectory(at: self.imagesDirectory, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                var savedPhotos = [SavedPhotoImage]()
                
                for directory in subdirectories {
                    
                    let photoFileURL = directory.appendingPathComponent("photo.json")
                    let photoData = try Data(contentsOf: photoFileURL)
                    let photo = try JSONDecoder().decode(Photo.self, from: photoData)
                    
                    let imageFileURL = directory.appendingPathComponent("image.png")
                    let imageData = try Data(contentsOf: imageFileURL)
                    let image = UIImage(data: imageData)!
                    
                    let savedPhoto = SavedPhotoImage(photo: photo, image: image)
                    savedPhotos.append(savedPhoto)
                }
                
                observer.onNext(savedPhotos)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
}
