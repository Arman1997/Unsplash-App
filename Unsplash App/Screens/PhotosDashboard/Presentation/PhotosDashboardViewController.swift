//
//  PhotosDashboardViewController.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

final class PhotosDashboardViewController: UIViewController {
    
    private let viewModel: PhotosDashboardViewModel
    private let disposeBag: DisposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private var photos: [PhotoCellDescriptor] = [PhotoCellDescriptor]()
    private let loadingActivity: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let cachedImages = NSCache<NSString,UIImage>()
    
    lazy var collectionView: UICollectionView = {
        let collectionViewLayout = CustomCollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: CustomCollectionViewCell.identifier)
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        return collectionView
    }()
    
    private struct Inputs {
        static let viewDidLoaded = PublishSubject<Void>()
        static let searchText = PublishSubject<String>()
        static let selectedImageIndex = PublishSubject<Int>()
        static let pulledToRefresh = PublishSubject<Void>()
        static let nextPageRequested = PublishSubject<Void>()
    }
    
    init(viewModel: PhotosDashboardViewModel = PhotosDashboardViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewModel()
    }
    
    @objc
    func onRefresh() {
        Inputs.pulledToRefresh.onNext(())
        refreshControl.endRefreshing()
    }
}

private extension PhotosDashboardViewController {
    func setupView() {
        if let layout = collectionView.collectionViewLayout as? CustomCollectionViewLayout {
          layout.delegate = self
        }
        
        self.view.backgroundColor = UIColor.white
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
        view.addSubview(loadingActivity)
    }
    
    func bindViewModel() {
        let output = viewModel.transform(
            input: .init(
                viewDidLoaded: Inputs.viewDidLoaded,
                searchText: Inputs.searchText,
                selectedImageIndex: Inputs.selectedImageIndex,
                pulledToRefresh: Inputs.pulledToRefresh,
                nextPageRequested: Inputs.nextPageRequested
            )
        )
        
        output
            .state
            .subscribe(onNext: { [weak self] state in
                guard let `self` = self else { return }
                
                switch state {
                case .loading:
                    loadingActivity.startAnimating()
                    return
                case .loaded(let descriptor):
                    self.cachedImages.removeAllObjects()
                    self.photos = descriptor.images
                    self.collectionView.reloadData()
                    loadingActivity.stopAnimating()
                    return
                case .error(let error):
                    loadingActivity.stopAnimating()
                    return
                case .nextPage(let descriptor):
                    let lastIndex = photos.count - 1
                    photos = descriptor.images
                    self.collectionView.performBatchUpdates { [weak self] in
                        guard let `self` = self else { return }
                        self.collectionView.insertItems(at: [IndexPath.init(row: lastIndex, section: 0)])
                    }
                    loadingActivity.stopAnimating()
                    return
                }
            })
            .disposed(by: disposeBag)
        
        output
            .actions
            .subscribe()
            .disposed(by: disposeBag)
    }
}

extension PhotosDashboardViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Inputs.selectedImageIndex.onNext(indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.identifier, for: indexPath) as? CustomCollectionViewCell else {
            fatalError("Unable to dequeue CustomCollectionViewCell")
        }
        let photoData = photos[indexPath.row]
        
        if let cachedVersion = self.cachedImages.object(forKey: NSString(string: photoData.imageId)) {
            cell.imageView.image = cachedVersion
        } else {
            photoData.imageChannel.subscribe(onNext: { [weak self, weak cell] image in
                guard let `self` = self, let cell = cell else { return }
                cell.imageView.image = image
                self.cachedImages.setObject(image, forKey: NSString(string: photoData.imageId))
            })
            .disposed(by: cell.disposeBag)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == photos.count - 1 {
            Inputs.nextPageRequested.onNext(())
        }
    }
}

extension PhotosDashboardViewController: UISearchControllerDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        Inputs.searchText.onNext("")
    }
}

extension PhotosDashboardViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Inputs.searchText.onNext(searchText)
    }
}

extension PhotosDashboardViewController: CustomLayoutDelegate {
  func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
      return photos[indexPath.item].imageHeight
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
      guard cache.isEmpty, let collectionView = collectionView else {
          return
      }

      let columnWidth = contentWidth / CGFloat(numberOfColumns)
      var xOffset: [CGFloat] = []
      for column in 0..<numberOfColumns {
        xOffset.append(CGFloat(column) * columnWidth)
      }
        
      var column = 0
      var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
      for item in 0..<collectionView.numberOfItems(inSection: 0) {
        let indexPath = IndexPath(item: item, section: 0)
        let photoHeight = delegate?.collectionView(collectionView, heightForPhotoAtIndexPath: indexPath) ?? 180
        let height = cellPadding * 2 + photoHeight
        let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
        let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = insetFrame
        cache.append(attributes)
        contentHeight = max(contentHeight, frame.maxY)
        yOffset[column] = yOffset[column] + height
        column = column < (numberOfColumns - 1) ? (column + 1) : 0
      }
    }
    
    override func layoutAttributesForElements(in rect: CGRect)
        -> [UICollectionViewLayoutAttributes]? {
      var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
      
      for attributes in cache {
        if attributes.frame.intersects(rect) {
          visibleLayoutAttributes.append(attributes)
        }
      }
      return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
      return cache[indexPath.item]
    }
}

class CustomCollectionViewCell: UICollectionViewCell {
    static let identifier = "CustomCollectionViewCell"
    let imageView: UIImageView = UIImageView()
    private let shadowContainerView: UIView = UIView()
    var disposeBag: DisposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        disposeBag = DisposeBag()
    }
    
    private func setupViews() {
        imageView.contentMode = .scaleAspectFill
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



func getData(page: Int) {

    // 1. Create the base URL
    guard var urlComponents = URLComponents(string: "https://api.unsplash.com/photos/random/") else {
        fatalError("Invalid URL")
    }

    // 2. Define the query parameters
    let queryItems = [
        URLQueryItem(name: "client_id", value: "EvILfIMijnKKj240kEwvZBrFPvdI9LR4Mc2LtdtlIH4"),
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "per_page", value: "20"),
    ]

    // 3. Add the query parameters to the URL
    urlComponents.queryItems = queryItems

    // 4. Get the final URL with the query parameters
    guard let url = urlComponents.url else {
        fatalError("Unable to get URL with query parameters")
    }

    // 5. Create a URLRequest
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    // 6. Create the URLSession
    let session = URLSession.shared

    // 7. Create the data task
    let task = session.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("Server error")
            return
        }

        if let data = data {
            // Handle the data (e.g., parse JSON)
            let str = String(decoding: data, as: UTF8.self)
            print(str)
            print("Data: \(data)")
        }
    }

    // 8. Start the task
    task.resume()
}
