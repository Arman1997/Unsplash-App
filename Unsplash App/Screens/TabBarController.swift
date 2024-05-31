//
//  TabBarController.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 31.05.24.
//

import Foundation
import UIKit

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewControllers = [initialTabBar, finalTabBar]
    }
        
        lazy public var initialTabBar: PhotosDashboardViewController = {
            let initialTabBar = PhotosDashboardViewController()
            let title = "Photos"
            let tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: "square.stack"), selectedImage: UIImage(systemName: "square.stack.fill"))
            initialTabBar.tabBarItem = tabBarItem
            return initialTabBar
        }()
        
        lazy public var finalTabBar: FavoritesViewController = {
            let finalTabBar = FavoritesViewController()
            let tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "heart.square"), selectedImage: UIImage(systemName: "heart.square.fill"))
            finalTabBar.tabBarItem = tabBarItem
            
            return finalTabBar
        }()

        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
}
