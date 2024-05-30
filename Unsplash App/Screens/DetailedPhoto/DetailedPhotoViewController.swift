//
//  DetailedPhotoViewController.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import UIKit

class DetailedPhotoViewController: UIViewController {
    private let image: UIImage
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Photo details"
        view.backgroundColor = .white
        
        
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.red
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.image = image
        
        let autorNameLabel = UILabel()
        autorNameLabel.text = "Author name"
        autorNameLabel.font = UIFont.systemFont(ofSize: 24.0)
        autorNameLabel.backgroundColor = UIColor.blue
        
        let contentView = vStack(
            views: [
                imageView,
                autorNameLabel,
                .empty
            ]
        )
        
        view.addSubview(contentView)
        contentView.layout {
            $0.top == view.safeAreaLayoutGuide.topAnchor + 24.0
            $0.leading == view.safeAreaLayoutGuide.leadingAnchor + 12.0
            $0.trailing == view.safeAreaLayoutGuide.trailingAnchor - 12.0
            $0.bottom == view.safeAreaLayoutGuide.bottomAnchor - 12
        }
    }
}
