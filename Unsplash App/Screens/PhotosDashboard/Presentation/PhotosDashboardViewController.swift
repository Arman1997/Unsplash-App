//
//  PhotosDashboardViewController.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import UIKit

final class PhotosDashboardViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.navigationController?.pushViewController(DetailedPhotoViewController(image: photos[indexPath.row]), animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.identifier, for: indexPath) as? CustomCollectionViewCell else {
            fatalError("Unable to dequeue CustomCollectionViewCell")
        }
        
        
        let data = photos[indexPath.row]
        cell.configure(withImage: data)
        
        return cell
    }
    let refreshControl = UIRefreshControl()
    lazy var collectionView: UICollectionView = {
        let collectionViewLayout = CustomCollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: CustomCollectionViewCell.identifier)
        refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let layout = collectionView.collectionViewLayout as? CustomCollectionViewLayout {
          layout.delegate = self
        }
        self.view.backgroundColor = .white
        self.title = "Unsplash photos"
        
        view.addSubview(collectionView)
        collectionView.layout {
            $0.top == view.safeAreaLayoutGuide.topAnchor
            $0.bottom == view.safeAreaLayoutGuide.bottomAnchor
            $0.leading == view.safeAreaLayoutGuide.leadingAnchor
            $0.trailing == view.safeAreaLayoutGuide.trailingAnchor
        }
        
        let search = UISearchController(searchResultsController: nil)
        search.delegate = self
        search.searchBar.delegate = self
        self.navigationItem.searchController = search
        

    }
    
    @objc
    func loadData() {
        print("refreshed")
        refreshControl.endRefreshing()
    }
    
    private let photos: [UIImage] = [
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
}

extension PhotosDashboardViewController: UISearchControllerDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    }
}

extension PhotosDashboardViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
}

extension PhotosDashboardViewController: CustomLayoutDelegate {
  func collectionView(
      _ collectionView: UICollectionView,
      heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
    return photos[indexPath.item].size.height
  }
}


protocol CustomLayoutDelegate: AnyObject {
  func collectionView(
    _ collectionView: UICollectionView,
    heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat
}

class CustomCollectionViewLayout: UICollectionViewLayout {
    weak var delegate: CustomLayoutDelegate?
    
    private let numberOfColumns = 2
    private let cellPadding: CGFloat = 6

    
    private var cache: [UICollectionViewLayoutAttributes] = []

    
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
      guard let collectionView = collectionView else {
        return 0
      }
      let insets = collectionView.contentInset
      return collectionView.bounds.width - (insets.left + insets.right)
    }

    
    override var collectionViewContentSize: CGSize {
      return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func prepare() {
      // 1
      guard
        cache.isEmpty,
        let collectionView = collectionView
        else {
          return
      }
      // 2
      let columnWidth = contentWidth / CGFloat(numberOfColumns)
      var xOffset: [CGFloat] = []
      for column in 0..<numberOfColumns {
        xOffset.append(CGFloat(column) * columnWidth)
      }
      var column = 0
      var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
        
      // 3
      for item in 0..<collectionView.numberOfItems(inSection: 0) {
        let indexPath = IndexPath(item: item, section: 0)
          
        // 4
        let photoHeight = delegate?.collectionView(
          collectionView,
          heightForPhotoAtIndexPath: indexPath) ?? 180
        let height = cellPadding * 2 + photoHeight
        let frame = CGRect(x: xOffset[column],
                           y: yOffset[column],
                           width: columnWidth,
                           height: height)
        let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
          
        // 5
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = insetFrame
        cache.append(attributes)
          
        // 6
        contentHeight = max(contentHeight, frame.maxY)
        yOffset[column] = yOffset[column] + height
        
        column = column < (numberOfColumns - 1) ? (column + 1) : 0
      }
    }
    
    override func layoutAttributesForElements(in rect: CGRect)
        -> [UICollectionViewLayoutAttributes]? {
      var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
      
      // Loop through the cache and look for items in the rect
      for attributes in cache {
        if attributes.frame.intersects(rect) {
          visibleLayoutAttributes.append(attributes)
        }
      }
      return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
      return cache[indexPath.item]
    }

}

class CustomCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "CustomCollectionViewCell"
    private let imageView: UIImageView = UIImageView()
    private let shadowContainerView: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(shadowContainerView)
        shadowContainerView.layout {
            $0.top == topAnchor
            $0.bottom == bottomAnchor
            $0.leading == leadingAnchor
            $0.trailing == trailingAnchor
        }
        
        shadowContainerView.addSubview(imageView)
        imageView.layout {
            $0.top == shadowContainerView.topAnchor
            $0.bottom == shadowContainerView.bottomAnchor
            $0.leading == shadowContainerView.leadingAnchor
            $0.trailing == shadowContainerView.trailingAnchor
        }
    }
    
    private func setupAppearance() {
        addShadowToView(view: shadowContainerView, value: 3.0)
        addCornerToView(view: imageView, value: 8)
    }
    
    func configure(withImage image: UIImage) {
        imageView.image = image
    }
}

func addShadowToView(view : UIView, value: CGFloat) {
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOffset = CGSize(width: value, height: value)
    view.layer.shadowOpacity = 0.25
    view.layer.shadowRadius = 4
    view.clipsToBounds = false
}

func addCornerToView (view : UIView, value: CGFloat) {
    view.layer.cornerRadius = value
    view.clipsToBounds = true
}
