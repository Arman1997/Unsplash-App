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
    private let loadingActivity: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    private let cachedImages = NSCache<NSString,UIImage>()
    private let collectionViewLayout = CustomCollectionViewLayout()
    
    lazy var collectionView: UICollectionView = {
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
        static let searchButtonTapped = PublishSubject<Void>()
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
        
        loadingActivity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingActivity)
        loadingActivity.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingActivity.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingActivity.color = UIColor.black
        
        
        self.view.backgroundColor = UIColor.white
        self.title = "Unsplash photos"
        view.addSubview(collectionView)
        collectionView.layout {
            $0.top == view.safeAreaLayoutGuide.topAnchor + 24.0
            $0.bottom == view.safeAreaLayoutGuide.bottomAnchor - 24.0
            $0.leading == view.safeAreaLayoutGuide.leadingAnchor + 8.0
            $0.trailing == view.safeAreaLayoutGuide.trailingAnchor - 8.0
        }
        
        let search = UISearchController(searchResultsController: nil)
        search.delegate = self
        search.searchBar.delegate = self
        self.navigationItem.searchController = search
    }
    
    func bindViewModel() {
        let output = viewModel.transform(
            input: .init(
                viewDidLoaded: Inputs.viewDidLoaded,
                searchText: Inputs.searchText,
                searchButtonTapped: Inputs.searchButtonTapped,
                selectedImageIndex: Inputs.selectedImageIndex,
                pulledToRefresh: Inputs.pulledToRefresh,
                nextPageRequested: Inputs.nextPageRequested
            )
        )
        
        output
            .state
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] state in
                guard let `self` = self else { return }
                
                switch state {
                case .loading(let isLoading):
                    view.bringSubviewToFront(loadingActivity)
                    isLoading ? loadingActivity.startAnimating() : loadingActivity.stopAnimating()
                case .loaded(let descriptor):
                    self.photos = descriptor.images
                    self.collectionViewLayout.cache.removeAll()
                    self.collectionView.reloadData()
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    self.collectionView.layoutIfNeeded()
                    self.collectionView.invalidateIntrinsicContentSize()
                case .error(let error):
                    return
                case .nextPage(let descriptor):
                    let indexesToUpdate = (self.photos.count ... descriptor.images.count - 1).map { IndexPath.init(row: $0, section: 0) }
                    self.photos = descriptor.images
                    self.collectionViewLayout.cache.removeAll()
                    self.collectionView.performBatchUpdates {
                        self.collectionView.insertItems(at: indexesToUpdate)
                    }
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    self.collectionView.invalidateIntrinsicContentSize()
                    return
                }
            })
            .disposed(by: disposeBag)
        
        output
            .navigateToPhotoDetails
            .subscribe(onNext: { [weak self] photoData in
                guard let `self` = self, 
                let navController = self.navigationController else {
                    return
                }

                navController
                    .pushViewController(
                        DetailedPhotoViewController(
                            DetailedPhotoViewModel(
                                useCases: DetailedPhotoViewModel.UseCases(
                                    isFavoriteUseCase: IsFavoriteUseCase(),
                                    saveFavorite: SaveFavoriteUseCase(),
                                    removeFavorite: RemoveFavoriteUseCase(),
                                    getBigSizedPhoto: GetBigSizedPhotoUseCase()
                                ),
                                mappers: DetailedPhotoViewModel.Mappers(
                                    descriptor: DetailedPhotoDescriptorMapper()
                                ),
                                configs: DetailedPhotoViewModel.Configs(
                                    photo: photoData
                                )
                            )
                        ),
                        animated: true
                    )

            }).disposed(by: disposeBag)
        
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
            photoData.imageChannel.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self, weak cell] image in
                guard let `self` = self, let cell = cell else { return }
                cell.imageView.image = image
                self.cachedImages.setObject(image, forKey: NSString(string: photoData.imageId))
            })
            .disposed(by: cell.disposeBag)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == photos.count - 1 {
            Inputs.nextPageRequested.onNext(())
        }
    }
}

extension PhotosDashboardViewController: UISearchControllerDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        Inputs.searchText.onNext("")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        Inputs.searchButtonTapped.onNext(())
    }
}

extension PhotosDashboardViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Inputs.searchText.onNext(searchText)
    }
}

extension PhotosDashboardViewController: CustomLayoutDelegate {
  func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
      let photo = photos[indexPath.item]
      let width = (UIScreen.main.bounds.width -  16.0 - 6) / 2.0
      let height = photo.imageHeight / (photo.imageWidth / width)
      return height
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
    var cache: [UICollectionViewLayoutAttributes] = []
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

