//
//  ARManager.swift
//  ARDemo
//
//  Created by Konrad Zdunczyk on 06/12/15.
//  Copyright © 2015 Konrad Zdunczyk. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation

class ARManager: NSObject {
    fileprivate var infiniteScrollView: InfiniteScrollView
    fileprivate var locations = [CLLocation]()
    fileprivate var lastUserLocation: CLLocation?
    
    init(infiniteScrollView: InfiniteScrollView) {
        self.infiniteScrollView = infiniteScrollView
        
        super.init()
        
        self.infiniteScrollView.iSDelegate = self
    }
    
    func addLocation(_ location: CLLocation) {
        locations.append(location)
        
        infiniteScrollView.refreshViews()
    }
    
    fileprivate func getAzimuthBetweenUserLocation(_ firstLocation: CLLocationCoordinate2D, andLocation secondLocation: CLLocationCoordinate2D) -> Double {
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
    
    fileprivate func radiansToDegree(_ radians: Double) -> Double {
        return radians * (180.0 / M_PI)
    }
}

extension ARManager: InfiniteScrollViewDelegate {
    func arViewForWithFrame(_ frame: CGRect, andPointsPerDegree pointsPerDegree: Double) -> UIView {
        let view = UIView(frame: frame)
        
        if let lastUserLocation = lastUserLocation {
            for location in locations {
                let azimuthRadians = getAzimuthBetweenUserLocation(lastUserLocation.coordinate, andLocation: location.coordinate)
                let azimuthDegree = radiansToDegree(azimuthRadians)
                let distance = lastUserLocation.distance(from: location)
                let locationPoint = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 25))
                locationPoint.center.x = CGFloat(azimuthDegree * pointsPerDegree)
                locationPoint.center.y = frame.midY
                locationPoint.backgroundColor = UIColor.black
                
                let distanceStr: String
                
                if distance > 100 {
                    distanceStr = String(format: "%.2lf km", distance / 1000.0)
                } else {
                    distanceStr = String(format: "%.2lf m", distance)
                }
                
                let label = UILabel(frame: CGRect(x: 0, y: locationPoint.frame.maxY, width: 100, height: 30))
                label.text = distanceStr
                label.textColor = UIColor.white
                label.backgroundColor = UIColor.black
                label.textAlignment = .center
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
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let magneticHeading: CLLocationDirection = newHeading.magneticHeading
        
        DispatchQueue.main.async { () -> Void in
            self.infiniteScrollView.setContentOffsetForDegree(magneticHeading)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastUserLocation = locations.last
        infiniteScrollView.refreshViews()
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        if let heading = manager.heading {
            return heading.headingAccuracy < 0 || heading.headingAccuracy > 5
        } else {
            return true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

}
