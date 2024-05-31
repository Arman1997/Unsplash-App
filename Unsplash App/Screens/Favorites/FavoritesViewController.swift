//
//  FavoritesViewController.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 31.05.24.
//

import Foundation
import UIKit

class FavoritesViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: .main)
        self.title = "Favorites"
        self.tabBarItem.image = UIImage(systemName: "heart.square.fill")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Favorites"
        view.backgroundColor = UIColor.white
    }
    
}
