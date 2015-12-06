//
//  InfiniteScrollView.swift
//  SoftaxTest
//
//  Created by Konrad Zdunczyk on 06/12/15.
//  Copyright © 2015 Konrad Zdunczyk. All rights reserved.
//

import UIKit

class InfiniteScrollView: UIScrollView {
    private var containerView: UIView!
    private var visibleViews = [UIView]()
    private var lastDegree: Double = 0
    private var cameraFoV: Double = 0
    
    var pointsPerDegree: Double {
        if (cameraFoV <= 0) {
            return 0
        }
        
        return Double(self.frame.width) / cameraFoV
    }
    
    private init() {
        super.init(frame: CGRectZero)
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
    
    private func scrollViewSetup() {
        contentSize = CGSize(width: 4000, height: frame.size.height)
        backgroundColor = UIColor.clearColor()
        userInteractionEnabled = false
        showsHorizontalScrollIndicator = true
        showsVerticalScrollIndicator = true
    }
    
    private func createContainerViewWithFrame(containerViewFrame: CGRect) -> UIView {
        let containerView = UIView()
        
        containerView.frame = containerViewFrame
        containerView.backgroundColor = UIColor.clearColor()
        containerView.userInteractionEnabled = false
        
        return containerView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        recenterIfNecessary()
        
        let visibleBounds = convertRect(bounds, toView: containerView)
        let minimumVisibleX = CGRectGetMinX(visibleBounds)
        let maximumVisibleX = CGRectGetMaxX(visibleBounds)
        
        tileViewsFromMinX(minimumVisibleX, toMaxX: maximumVisibleX)
    }
    
    func setContentOffsetForDegree(degree: Double) {
        var tX = degree - lastDegree
        tX *= pointsPerDegree
        
        var newContentOffset = contentOffset
        newContentOffset.x += CGFloat(tX)
        lastDegree = degree
        
        setContentOffset(newContentOffset, animated: false)
    }
    
    // MARK: - views managment
    private func recenterIfNecessary() {
        let currentOffset = contentOffset
        let contentWidth = contentSize.width
        let centerOffsetX = (contentWidth - bounds.size.width) / 2.0
        let distanceFromCenter = fabs(currentOffset.x - centerOffsetX)
        
        if distanceFromCenter > contentWidth / 4.0 {
            contentOffset = CGPoint(x: centerOffsetX, y: currentOffset.y)
            
            for view in visibleViews {
                var newCenter = containerView.convertPoint(view.center, toView: self)
                newCenter.x += (centerOffsetX - currentOffset.x)
                view.center = convertPoint(newCenter, toView: containerView)
            }
        }
    }
    
    private func insertView() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat(360 * pointsPerDegree), height: self.frame.height))
        view.backgroundColor = UIColor.clearColor()
        
        for i in 0..<36 {
            let line = UIView(frame: CGRect(x: Double(i * 10) * pointsPerDegree, y: 0, width: 1, height: 10))
            line.backgroundColor = UIColor.blackColor()
            let label = UILabel(frame: CGRect(x: line.frame.origin.x, y: CGRectGetMaxY(line.frame), width: 50, height: 20))
            label.textAlignment = .Left
            label.text = "\(i * 10)°"
            label.textColor = UIColor.blackColor()
            
            view.addSubview(line)
            view.addSubview(label)
        }
        
        containerView.addSubview(view)
        
        return view
    }
    
    private func placeNewViewOnRight(rightEdge: CGFloat) -> CGFloat {
        let view = insertView()
        visibleViews.append(view)
        
        var viewFrame = view.frame
        viewFrame.origin.x = rightEdge
        viewFrame.origin.y = 0
        view.frame = viewFrame
        
        return CGRectGetMaxX(viewFrame)
    }
    
    private func placeNewViewOnLeft(leftEdge: CGFloat) -> CGFloat {
        let view = insertView()
        visibleViews.insert(view, atIndex: 0)
        
        var viewFrame = view.frame
        viewFrame.origin.x = leftEdge - viewFrame.size.width
        viewFrame.origin.y = 0
        view.frame = viewFrame
        
        return CGRectGetMinX(viewFrame)
    }
    
    private func tileViewsFromMinX(minX: CGFloat, toMaxX maxX: CGFloat) {
        if visibleViews.count == 0 {
            placeNewViewOnRight(minX + (maxX - minX) / 2)
        }
        
        var rightEdge: CGFloat = 0
        if let lastView = visibleViews.last {
            rightEdge = CGRectGetMaxX(lastView.frame)
            
            while rightEdge < maxX {
                rightEdge = placeNewViewOnRight(rightEdge)
            }
        }
        
        var leftEdge: CGFloat = 0
        if let firstView = visibleViews.first {
            leftEdge = CGRectGetMinX(firstView.frame)
            
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
        while firstView != nil && CGRectGetMaxX(firstView!.frame) < minX {
            firstView!.removeFromSuperview()
            visibleViews.removeFirst()
            firstView = visibleViews.first
        }
    }
}
