//
//  InfiniteScrollView.swift
//  ARDemo
//
//  Created by Konrad Zdunczyk on 06/12/15.
//  Copyright © 2015 Konrad Zdunczyk. All rights reserved.
//

import UIKit

protocol InfiniteScrollViewDelegate: class {
    func arViewForWithFrame(_ frame: CGRect, andPointsPerDegree pointsPerDegree: Double) -> UIView
    func shouldInfiniteScrollDisplayCompasLine() -> Bool
}

class InfiniteScrollView: UIScrollView {
    fileprivate var containerView: UIView!
    fileprivate var visibleViews = [UIView]()
    fileprivate var lastDegree: Double = 0
    fileprivate var cameraFoV: Double = 0
    
    weak var iSDelegate: InfiniteScrollViewDelegate?
    
    var pointsPerDegree: Double {
        if (cameraFoV <= 0) {
            return 0
        }
        
        return Double(self.frame.width) / cameraFoV
    }
    
    fileprivate init() {
        super.init(frame: CGRect.zero)
    }
    
    init(frame: CGRect, cameraFieldOfView cameraFoV: Double) {
        super.init(frame: frame)
        
        self.cameraFoV = cameraFoV
        
        scrollViewSetup()
        
        containerView = createContainerViewWithFrame(CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height))
        addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func scrollViewSetup() {
        contentSize = CGSize(width: 4000, height: frame.size.height)
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = false
        showsHorizontalScrollIndicator = true
        showsVerticalScrollIndicator = true
    }
    
    fileprivate func createContainerViewWithFrame(_ containerViewFrame: CGRect) -> UIView {
        let containerView = UIView()
        
        containerView.frame = containerViewFrame
        containerView.backgroundColor = UIColor.clear
        containerView.isUserInteractionEnabled = false
        
        return containerView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        recenterIfNecessary()
        
        let visibleBounds = convert(bounds, to: containerView)
        let minimumVisibleX = visibleBounds.minX
        let maximumVisibleX = visibleBounds.maxX
        
        tileViewsFromMinX(minimumVisibleX, toMaxX: maximumVisibleX)
    }
    
    func setContentOffsetForDegree(_ degree: Double) {
        var tX = degree - lastDegree
        tX *= pointsPerDegree
        
        var newContentOffset = contentOffset
        newContentOffset.x += CGFloat(tX)
        lastDegree = degree
        
        setContentOffset(newContentOffset, animated: false)
    }
    
    func refreshViews() {
        for (index, view) in visibleViews.enumerated() {
            if let newView = insertView() {
                newView.frame = view.frame
                view.removeFromSuperview()
                self.addSubview(newView)
                visibleViews[index] = newView
            }
        }
    }
    
    // MARK: - views managment
    fileprivate func recenterIfNecessary() {
        let currentOffset = contentOffset
        let contentWidth = contentSize.width
        let centerOffsetX = (contentWidth - bounds.size.width) / 2.0
        let distanceFromCenter = fabs(currentOffset.x - centerOffsetX)
        
        if distanceFromCenter > contentWidth / 4.0 {
            contentOffset = CGPoint(x: centerOffsetX, y: currentOffset.y)
            
            for view in visibleViews {
                var newCenter = containerView.convert(view.center, to: self)
                newCenter.x += (centerOffsetX - currentOffset.x)
                view.center = convert(newCenter, to: containerView)
            }
        }
    }
    
    fileprivate func insertView() -> UIView? {
        let viewFrame = CGRect(x: 0, y: 0, width: CGFloat(360 * pointsPerDegree), height: self.frame.height)
        
        if let view = iSDelegate?.arViewForWithFrame(viewFrame, andPointsPerDegree: pointsPerDegree) {
            view.backgroundColor = UIColor.clear
            
            if let delegate = iSDelegate, delegate.shouldInfiniteScrollDisplayCompasLine() {
                for i in 0..<36 {
                    let line = UIView(frame: CGRect(x: Double(i * 10) * pointsPerDegree, y: 0, width: 1, height: 10))
                    line.backgroundColor = UIColor.black
                    let label = UILabel(frame: CGRect(x: line.frame.origin.x, y: line.frame.maxY, width: 50, height: 20))
                    label.textAlignment = .left
                    label.text = "\(i * 10)°"
                    label.textColor = UIColor.black
                    
                    view.addSubview(line)
                    view.addSubview(label)
                }
            }
            
            containerView.addSubview(view)
            
            return view
        }
        
        return nil
    }
    
    fileprivate func placeNewViewOnRight(_ rightEdge: CGFloat) -> CGFloat {
        guard let view = insertView() else {
            return -1
        }
        
        visibleViews.append(view)
        
        var viewFrame = view.frame
        viewFrame.origin.x = rightEdge
        viewFrame.origin.y = 0
        view.frame = viewFrame
        
        return viewFrame.maxX
    }
    
    fileprivate func placeNewViewOnLeft(_ leftEdge: CGFloat) -> CGFloat {
        guard let view = insertView() else {
            return -1
        }
        
        visibleViews.insert(view, at: 0)
        
        var viewFrame = view.frame
        viewFrame.origin.x = leftEdge - viewFrame.size.width
        viewFrame.origin.y = 0
        view.frame = viewFrame
        
        return viewFrame.minX
    }
    
    fileprivate func tileViewsFromMinX(_ minX: CGFloat, toMaxX maxX: CGFloat) {
        if visibleViews.count == 0 {
            if placeNewViewOnRight(minX + (maxX - minX) / 2) == -1 {
                return
            }
        }
        
        var rightEdge: CGFloat = 0
        if let lastView = visibleViews.last {
            rightEdge = lastView.frame.maxX
            
            while rightEdge < maxX {
                rightEdge = placeNewViewOnRight(rightEdge)
            }
        }
        
        var leftEdge: CGFloat = 0
        if let firstView = visibleViews.first {
            leftEdge = firstView.frame.minX
            
            while leftEdge > minX {
                leftEdge = placeNewViewOnLeft(leftEdge)
            }
        }
        
        var lastView = visibleViews.last
        while lastView != nil && lastView!.frame.origin.x > maxX {
            lastView!.removeFromSuperview()
            visibleViews.removeLast()
            lastView = visibleViews.last
        }
        
        var firstView = visibleViews.first
        while firstView != nil && firstView!.frame.maxX < minX {
            firstView!.removeFromSuperview()
            visibleViews.removeFirst()
            firstView = visibleViews.first
        }
    }
}
