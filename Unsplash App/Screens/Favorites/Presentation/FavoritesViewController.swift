//
//  FavoritesViewController.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 31.05.24.
//

import Foundation
import UIKit
import RxSwift

class FavoritesViewController: UIViewController {
    private let viewModel: FavoritesViewModel
    private let disposeBag = DisposeBag()
    private var images = [UIImage]()
    private let loadingActivity: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    
    init(_ viewModel: FavoritesViewModel = FavoritesViewModel(useCases: FavoritesViewModel.UseCases.init(getAllFavorites: GetAllFavoritesUseCases()))) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: .main)
        self.title = "Favorites"
        self.tabBarItem.image = UIImage(systemName: "heart.square.fill")
    }
    
    struct Inputs {
        static let viewDidLoad = PublishSubject<Void>()
        static let viewDidAppear = PublishSubject<Void>()
        static let imageWithIndexSelected = PublishSubject<Int>()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewModel()
        Inputs.viewDidLoad.onNext(())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch UIScreen.main.traitCollection.userInterfaceStyle {
          case .dark:
            self.view.backgroundColor = .black
          case .light:
            self.view.backgroundColor = .white
        default:
            self.view.backgroundColor = .white
        }
        Inputs.viewDidAppear.onNext(())
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
}

extension FavoritesViewController {
    func setupView() {
        self.title = "Favorites"
        view.backgroundColor = UIColor.white
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadingActivity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingActivity)
        loadingActivity.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingActivity.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingActivity.color = UIColor.black
    }
    
    func bindViewModel() {
        let output = viewModel.transform(
            FavoritesViewModel.Input.init(
                viewDidLoad: Inputs.viewDidLoad,
                viewDidAppear: Inputs.viewDidAppear,
                imageWithIndexSelected: Inputs.imageWithIndexSelected
            )
        )
        
        output.state.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            
            switch state {
            case .loading(let isLoading):
                isLoading ? loadingActivity.startAnimating() : loadingActivity.stopAnimating()
            case .loaded(let descriptor):
                self.images = descriptor.images
                self.collectionView.reloadData()
            }
        }).disposed(by: disposeBag)
        
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
    }
}

extension FavoritesViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as! ImageCell
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 5
        let itemWidth = (collectionView.bounds.width - (numberOfColumns - 1)) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Inputs.imageWithIndexSelected.onNext(indexPath.row)
    }
}


class ImageCell: UICollectionViewCell {
    static let identifier = "ImageCell"
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleToFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.layout {
            $0.top == contentView.topAnchor
            $0.bottom == contentView.bottomAnchor
            $0.leading == contentView.leadingAnchor
            $0.trailing == contentView.trailingAnchor
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
