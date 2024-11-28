//
//  ImageCarouselViewController.swift
//  VisaPre
//
//  Created by Anubhav Singh on 27/11/24.
//

import UIKit

class ImageCarouselViewController: UIViewController {
    
    // MARK: - Constants
    private let carouselSpacing: CGFloat = -30
    private let zoomScaleDefault: CGFloat = 1.0
    private let zoomScaleMin: CGFloat = 0.85
    private let zoomScaleMax: CGFloat = 1.1
    private let imageCornerRadius: CGFloat = 8
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private var imageViews: [UIImageView] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupScrollView()
        setupPageControl()
        setupImageViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        positionImagesOnLaunch()
        applyZoomEffectToImages()
        applyCornerRadiusToImages()
    }
    
    // MARK: - Setup Methods
    private func setupScrollView() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.isPagingEnabled = false
        scrollView.decelerationRate = .fast
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scrollView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
        ])
    }
    
    private func setupPageControl() {
        pageControl.numberOfPages = 3
        pageControl.currentPage = 1
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = .lightGray
        view.addSubview(pageControl)
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8)
        ])
    }
    
    private func setupImageViews() {
        let images = loadImageAssets()
        var previousImageView: UIImageView?
        
        for (index, image) in images.enumerated() {
            let imageView = createImageView(with: image)
            scrollView.addSubview(imageView)
            imageViews.append(imageView)
            
            NSLayoutConstraint.activate([
                imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                imageView.widthAnchor.constraint(equalTo: scrollView.heightAnchor), // Square ratio
                imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
            ])
            
            if let previousImage = previousImageView {
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: previousImage.trailingAnchor, constant: carouselSpacing)
                ])
            } else {
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: calculateInitialLeadingOffset())
                ])
            }
            
            if index == images.count - 1 {
                NSLayoutConstraint.activate([
                    imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -calculateInitialLeadingOffset())
                ])
            }
            
            previousImageView = imageView
        }
    }
    
    // MARK: - Helper Methods
    private func loadImageAssets() -> [UIImage] {
        return (1...3).map { UIImage(named: "image\($0)") ?? UIImage() }
    }
    
    private func createImageView(with image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    private func calculateInitialLeadingOffset() -> CGFloat {
        return view.bounds.width / 2 - (view.bounds.width * 0.6) / 2
    }
    
    private func positionImagesOnLaunch() {
        let itemWidth = view.bounds.width * 0.46 + abs(carouselSpacing)
        scrollView.contentOffset = CGPoint(x: itemWidth, y: 0)
    }
    
    private func applyZoomEffectToImages() {
        let centerX = scrollView.contentOffset.x + scrollView.bounds.width / 2
        
        for (index, imageView) in imageViews.enumerated() {
            let distanceFromCenter = abs(centerX - imageView.center.x)
            let scale = index == 1 ? zoomScaleMax : zoomScaleMin
            imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            if index == 1 {
                scrollView.bringSubviewToFront(imageView) // Ensure center image is on top
            }
        }
    }
    
    private func applyCornerRadiusToImages() {
        for imageView in imageViews {
            imageView.layer.cornerRadius = imageCornerRadius
            imageView.layer.masksToBounds = true
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ImageCarouselViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustZoomForVisibleImages()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToClosestImage()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            snapToClosestImage()
        }
    }
    
    private func adjustZoomForVisibleImages() {
        let centerX = scrollView.contentOffset.x + scrollView.bounds.width / 2
        let itemWidth = view.bounds.width * 0.6 + abs(carouselSpacing)
        
        for imageView in imageViews {
            let distanceFromCenter = abs(centerX - imageView.center.x)
            let scale = max(zoomScaleMin, 1 - (distanceFromCenter / itemWidth) * 0.3)
            imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            if abs(distanceFromCenter) < itemWidth / 2 {
                scrollView.bringSubviewToFront(imageView)
            }
        }
    }
    
    private func snapToClosestImage() {
        let itemWidth = view.bounds.width * 0.6 + abs(carouselSpacing)
        let centerX = scrollView.contentOffset.x + scrollView.bounds.width / 2
        
        var closestImageView: UIImageView?
        var smallestDistance: CGFloat = .greatestFiniteMagnitude
        
        for imageView in imageViews {
            let distance = abs(centerX - imageView.center.x)
            if distance < smallestDistance {
                smallestDistance = distance
                closestImageView = imageView
            }
        }
        
        if let targetImageView = closestImageView {
            let targetOffsetX = targetImageView.center.x - scrollView.bounds.width / 2
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView.setContentOffset(CGPoint(x: targetOffsetX, y: 0), animated: false)
                for imageView in self.imageViews {
                    imageView.transform = imageView == targetImageView
                        ? CGAffineTransform(scaleX: self.zoomScaleDefault, y: self.zoomScaleDefault)
                        : CGAffineTransform(scaleX: self.zoomScaleMin, y: self.zoomScaleMin)
                }
            })
            
            if let index = imageViews.firstIndex(of: targetImageView) {
                pageControl.currentPage = index
            }
        }
    }
}

