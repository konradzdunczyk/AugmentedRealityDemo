//
//  ARManager.swift
//  SoftaxTest
//
//  Created by Konrad Zdunczyk on 06/12/15.
//  Copyright © 2015 Konrad Zdunczyk. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation

class ARManager: NSObject {
    private var infiniteScrollView: InfiniteScrollView
    private var locations = [CLLocation]()
    private var lastUserLocation: CLLocation?
    
    init(infiniteScrollView: InfiniteScrollView) {
        self.infiniteScrollView = infiniteScrollView
        
        super.init()
        
        self.infiniteScrollView.iSDelegate = self
    }
    
    func addLocation(location: CLLocation) {
        locations.append(location)
        
        infiniteScrollView.refreshViews()
    }
    
    private func getAzimuthBetweenUserLocation(firstLocation: CLLocationCoordinate2D, andLocation secondLocation: CLLocationCoordinate2D) -> Double {
        let longitudeDifference: Double = secondLocation.longitude - firstLocation.longitude;
        let latitudeDifference: Double = secondLocation.latitude  - firstLocation.latitude;
        let possibleAzimuth: Double = (M_PI * 0.5) - atan(latitudeDifference / longitudeDifference);
        
        if (longitudeDifference > 0) {
            return possibleAzimuth;
        } else if (longitudeDifference < 0) {
            return possibleAzimuth + M_PI;
        } else if (latitudeDifference < 0) {
            return M_PI;
        }
        
        return 0.0;
    }
    
    private func radiansToDegree(radians: Double) -> Double {
        return radians * (180.0 / M_PI)
    }
}

extension ARManager: InfiniteScrollViewDelegate {
    func arViewForWithFrame(frame: CGRect, andPointsPerDegree pointsPerDegree: Double) -> UIView {
        let view = UIView(frame: frame)
        
        if let lastUserLocation = lastUserLocation {
            for location in locations {
                let azimuthRadians = getAzimuthBetweenUserLocation(lastUserLocation.coordinate, andLocation: location.coordinate)
                let azimuthDegree = radiansToDegree(azimuthRadians)
                let distance = lastUserLocation.distanceFromLocation(location)
                let locationPoint = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 25))
                locationPoint.center.x = CGFloat(azimuthDegree * pointsPerDegree)
                locationPoint.center.y = CGRectGetMidY(frame)
                locationPoint.backgroundColor = UIColor.blackColor()
                
                let distanceStr: String
                
                if distance > 100 {
                    distanceStr = String(format: "%.2lf km", distance / 1000.0)
                } else {
                    distanceStr = String(format: "%.2lf m", distance)
                }
                
                let label = UILabel(frame: CGRect(x: 0, y: CGRectGetMaxY(locationPoint.frame), width: 100, height: 30))
                label.text = distanceStr
                label.textColor = UIColor.whiteColor()
                label.backgroundColor = UIColor.blackColor()
                label.textAlignment = .Center
                label.center.x = locationPoint.center.x
                label.numberOfLines = 1
                
                view.addSubview(locationPoint)
                view.addSubview(label)
            }
        }
        
        return view
    }
    
    func shouldInfiniteScrollDisplayCompasLine() -> Bool {
        return true
    }
}

extension ARManager: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let magneticHeading: CLLocationDirection = newHeading.magneticHeading
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.infiniteScrollView.setContentOffsetForDegree(magneticHeading)
        })
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        lastUserLocation = newLocation
        infiniteScrollView.refreshViews()
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
        if let heading = manager.heading {
            return heading.headingAccuracy < 0 || heading.headingAccuracy > 5
        } else {
            return true
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

}
