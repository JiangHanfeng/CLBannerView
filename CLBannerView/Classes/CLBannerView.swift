//
//  CLBannerView.swift
//
//  Created by Borya on 2020/4/9.
//  Copyright © 2020 Yuantel. All rights reserved.
//  v0.2.1

/*
 3个imageView循环滚动显示；scrollView始终显示的都是第二个imageView，即当scrollView滑动到第一个imageView或者第三个imageView的位置时，重新调整3个imageView所要显示的图片，然后将scrollView还原到第二个imageView的位置；
 在原始图片数组n的基础上，首项追加原始图片数组的末尾图，末尾追加原始图片数组第一张图
 */

import UIKit

public class CLBannerView: UIView, UIScrollViewDelegate {

    fileprivate var displayImages: [UIImage] = []
    fileprivate var imageViews: [UIImageView] = []
    fileprivate var timer: Timer?
    var currentIndex: Int = 0
    open var didSelectBanner: ((_ index: Int) -> Void)?
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: bounds)
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        return scrollView
    }()
    
    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl(frame: CGRect(x: 0, y: bounds.height - 20, width: bounds.width, height: 20))
        return pageControl
    }()
        
    deinit {
        scrollView.removeObserver(self, forKeyPath: "contentSize", context: nil)
        timer?.invalidate()
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if true == keyPath?.elementsEqual("contentSize") {
            initialState()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    public func addImage(image: UIImage) {
        guard displayImages.count > 2 else {
            return
        }
        displayImages.insert(image, at: displayImages.count - 2)
        displayImages.replaceSubrange(0..<1, with: [image])
    }
    
    public func replaceImage(image: UIImage, at index: Int) {
        guard index < displayImages.count - 2 else {
            return
        }
        displayImages.replaceSubrange(index..<index + 1, with: [image])
    }
    
    public func setImages(images: [UIImage]) {
        
        guard images.count > 0 else {
            return
        }
        
        displayImages.removeAll()
        
        displayImages.append(images.last!)
        displayImages.append(contentsOf: images)
        displayImages.append(images.first!)
        
        pageControl.numberOfPages = images.count
        
        if nil == scrollView.superview {
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(scrollView)
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: .alignAllCenterY, metrics: nil, views: ["scrollView":scrollView]))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: .alignAllCenterX, metrics: nil, views: ["scrollView":scrollView]))
            
            for i in 0..<3 {
                let imageView = UIImageView(frame: CGRect(x: scrollView.bounds.width * CGFloat(i), y: 0, width: scrollView.bounds.width, height: scrollView.bounds.height))
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleToFill
                imageView.image = displayImages[i]
                scrollView.addSubview(imageView)
                imageViews.append(imageView)

                imageView.isUserInteractionEnabled = true
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapImageView(tap:)))
                imageView.addGestureRecognizer(tap)
                
                scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|", options: .alignAllCenterX, metrics: nil, views: ["imageView":imageView]))
                addConstraint(NSLayoutConstraint.init(item: imageView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
                addConstraint(NSLayoutConstraint.init(item: imageView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
                var hFormat = "H:|"
                var views: [String : UIImageView?] = [:]
                for j in 0...i {
                    let imageViewKey = "imageView\(j)"
                    hFormat.append("[\(imageViewKey)]")
                    views.updateValue(imageViews[j], forKey: imageViewKey)
                }
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: hFormat, options: .alignAllCenterY, metrics: nil, views: views as [String : Any]))
                if i == 2 {
                    addConstraint(NSLayoutConstraint.init(item: imageView, attribute: .trailing, relatedBy: .equal, toItem: scrollView, attribute: .trailing, multiplier: 1, constant: 0))
                }
            }
        }
        
        if nil == pageControl.superview {
            pageControl.translatesAutoresizingMaskIntoConstraints = false
            addSubview(pageControl)
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[pageControl]|", options: .alignAllCenterY, metrics: nil, views: ["pageControl":pageControl]))
            addConstraint(NSLayoutConstraint.init(item: pageControl, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint.init(item: pageControl, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20))
        }
    }
    
    @objc func tapImageView(tap: UITapGestureRecognizer) {
        didSelectBanner?(pageControl.currentPage)
    }
    
    private func initialState() {
        guard displayImages.count > 2, imageViews.count > 2 else {
            return
        }
        currentIndex = 1
        imageViews.first?.image = displayImages[currentIndex - 1]
        imageViews[1].image = displayImages[currentIndex]
        imageViews.last?.image = displayImages[currentIndex + 1]
        pageControl.currentPage = currentIndex - 1
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width, y: 0), animated: false)
        timer?.invalidate()
        timer = nil
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (ti) in
            if let scrollView = self?.scrollView {
                scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width * 2.0, y: 0), animated: true)
            }
        })
        RunLoop.current.add(timer!, forMode: .commonModes)
    }
    
    private func adjustScrollPosition() {
        if 2 == scrollView.contentOffset.x / scrollView.bounds.width {
            currentIndex += 1;
            if currentIndex >= displayImages.count - 1 {
                currentIndex = 1
            }
            imageViews.first?.image = displayImages[currentIndex - 1]
            imageViews[1].image = displayImages[currentIndex]
            imageViews.last?.image = displayImages[currentIndex + 1]
            pageControl.currentPage = currentIndex - 1
            scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width, y: 0), animated: false)
        } else if 0 == scrollView.contentOffset.x {
            currentIndex -= 1
            if currentIndex <= 0 {
                currentIndex = displayImages.count - 2
            }
            imageViews.first?.image = displayImages[currentIndex - 1]
            imageViews[1].image = displayImages[currentIndex]
            imageViews.last?.image = displayImages[currentIndex + 1]
            pageControl.currentPage = currentIndex - 1
            scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width, y: 0), animated: false)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        adjustScrollPosition()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        adjustScrollPosition()
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer?.fireDate = Date.distantFuture
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        adjustScrollPosition()
        timer?.fireDate = Date.init(timeIntervalSinceNow: 5)
    }
}
