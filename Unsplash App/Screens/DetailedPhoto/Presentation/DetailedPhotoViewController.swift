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
        setupView()
        bindViewModel()
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
            .subscribe(onNext: { [weak self] state in
                guard let `self` = self else { return }
                switch state {
                case .loading(let isLoading):
                    isLoading ? loadingActivity.startAnimating() : loadingActivity.stopAnimating()
                case .loaded(let descriptor):
                    imageView.image = descriptor.image
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
        loadingActivity.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingActivity.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(imageView)
        imageView.layout {
            $0.top == view.safeAreaLayoutGuide.topAnchor + 8.0
            $0.leading == view.safeAreaLayoutGuide.leadingAnchor + 8.0
            $0.trailing == view.safeAreaLayoutGuide.trailingAnchor - 8.0
            $0.bottom == view.safeAreaLayoutGuide.bottomAnchor - UIScreen.main.bounds.height / 2.0
        }
        
        view.addSubview(loadingActivity)
    }
}
