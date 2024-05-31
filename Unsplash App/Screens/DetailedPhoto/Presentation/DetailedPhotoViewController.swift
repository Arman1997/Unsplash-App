//
//  DetailedPhotoViewController.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa


class DetailedPhotoViewController: UIViewController {
    private let viewModel: DetailedPhotoViewModel
    private let disposeBag: DisposeBag = DisposeBag()
    private let loadingActivity: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let imageView: UIImageView = UIImageView()
    
    private let authorNameLabel = FilledLabel()
    private let descriptionLabel = FilledLabel()
    private let dateCreatedLabel = FilledLabel()
    private let favoriteButton = FavoriteButton()
    
    
    struct Inputs {
        static let viewDidLoaded = PublishRelay<Void>()
        static let favoriteButtonTapped = PublishRelay<Void>()
    }
    
    init(_ viewModel: DetailedPhotoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        setupView()
        bindViewModel()
        Inputs.viewDidLoaded.accept(())
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
    }
    
    func bindViewModel() {
        let output = viewModel.transform(
            DetailedPhotoViewModel.Input(
                viewDidLoaded: Inputs.viewDidLoaded.asObservable(),
                favoriteButtonTapped: Inputs.favoriteButtonTapped.asObservable()
            )
        )
        
        output
            .state
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] state in
                guard let `self` = self else { return }
                switch state {
                case .loading(let isLoading):
                    isLoading ? loadingActivity.startAnimating() : loadingActivity.stopAnimating()
                case .loaded(let descriptor):
                    imageView.image = descriptor.image
                    authorNameLabel.text = descriptor.authorName
                    dateCreatedLabel.text = descriptor.dateCreated
                    descriptionLabel.text = descriptor.description
                    descriptionLabel.sizeToFit()
                    dateCreatedLabel.sizeToFit()
                    descriptor.isFavorite ? favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal) :
                    favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
                case .error(let error):
                    fatalError()
                }
            })
            .disposed(by: disposeBag)
        
        output.actions.subscribe().disposed(by: disposeBag)
        
    }
    
    func setupView() {
        self.title = "Photo details"
        loadingActivity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingActivity)
        loadingActivity.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingActivity.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.layout {
            $0.top == view.safeAreaLayoutGuide.topAnchor + 8.0
            $0.leading == view.safeAreaLayoutGuide.leadingAnchor + 8.0
            $0.trailing == view.safeAreaLayoutGuide.trailingAnchor - 8.0
            $0.bottom == view.safeAreaLayoutGuide.bottomAnchor - UIScreen.main.bounds.height / 3.0
        }
        
        let detailsContent = vStack(
            spacing: 8.0,
            views: [
                authorNameLabel,
                dateCreatedLabel,
                descriptionLabel
            ]
        )
        view.addSubview(detailsContent)
        detailsContent.layout {
            $0.top == imageView.bottomAnchor + 16.0
            $0.leading == view.safeAreaLayoutGuide.leadingAnchor + 8.0
            $0.trailing == view.safeAreaLayoutGuide.trailingAnchor - 8.0
        }
        
        view.addSubview(favoriteButton)
        favoriteButton.layout {
            $0.top == imageView.bottomAnchor - 2
            $0.trailing == view.safeAreaLayoutGuide.trailingAnchor - 30
        }
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }
    
    @objc
    func favoriteButtonTapped() {
        Inputs.favoriteButtonTapped.accept(())
    }
}

func FilledLabel() -> UILabel {
    let label = UILabel()
    label.textColor = UIColor.darkGray
    label.font = UIFont.systemFont(ofSize: 16)
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    return label
}

func FavoriteButton() -> UIButton {
    let button = UIButton()
    button.tintColor = UIColor.systemBlue
    button.setImage(UIImage(systemName: "heart"), for: .normal)
    return button
}
