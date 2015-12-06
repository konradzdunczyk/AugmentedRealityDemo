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
    
    init(infiniteScrollView: InfiniteScrollView) {
        self.infiniteScrollView = infiniteScrollView
        
        super.init()
    }
}

extension ARManager: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let magneticHeading: CLLocationDirection = newHeading.magneticHeading
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.infiniteScrollView.setContentOffsetForDegree(magneticHeading)
        })
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
        if let heading = manager.heading {
            return heading.headingAccuracy < 0 || heading.headingAccuracy > 5
        } else {
            return true
        }
    }
}
