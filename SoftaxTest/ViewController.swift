//
//  ViewController.swift
//  SoftaxTest
//
//  Created by Konrad Zdunczyk on 06/12/15.
//  Copyright © 2015 Konrad Zdunczyk. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import CoreMotion

class ViewController: UIViewController {
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    
    var avSession: AVCaptureSession!
    var previewView: UIView!
    var arManager: ARManager!
    var infiniteScrollView: InfiniteScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()
        
        previewView = makePreviewViewWithPoint(CGPoint(x: 0, y: 0), andWidth: view.frame.width)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.startUpdatingHeading()
        
        setup()

        let location_one = CLLocation(latitude: 52.24047435, longitude: 21.08225673)
        let location_two = CLLocation(latitude: 52.258830, longitude: 19.380461)
        let location_three = CLLocation(latitude: 51.937416, longitude: 21.997115)
        let location_four = CLLocation(latitude: 53.008583, longitude: 20.873048)
        let location_five = CLLocation(latitude: 51.396003, longitude: 21.148603)
        
        arManager.addLocation(location_one)
        arManager.addLocation(location_two)
        arManager.addLocation(location_three)
        arManager.addLocation(location_four)
        arManager.addLocation(location_five)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        avSession.stopRunning()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private func showAlertWithTitle(title: String, andMessage msg: String) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        let okAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        alertController.addAction(okAlertAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func showAlertAboutNoPermissionForGps() {
        showAlertWithTitle("Cannot use GPS", andMessage: "This app is not authorized to use GPS")
    }
    
    // MARK: - setup functions
    private func setup() {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        avSession = setupCameraPreviewWithPreview(previewView, andDevice: device)
        
        infiniteScrollView = InfiniteScrollView(frame: previewView.frame, cameraFieldOfView: Double(device.activeFormat.videoFieldOfView))
        arManager = ARManager(infiniteScrollView: infiniteScrollView)
        
        view.addSubview(previewView)
        view.addSubview(infiniteScrollView)
        
        locationManager.delegate = arManager
        
        if let avSession = avSession {
            avSession.startRunning()
        }
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .Restricted, .Denied:
            showAlertAboutNoPermissionForGps()
        default:
            break
        }
    }

    private func setupCameraPreviewWithPreview(preview: UIView, andDevice device: AVCaptureDevice) -> AVCaptureSession? {
        let avSession = AVCaptureSession()
        avSession.sessionPreset = AVCaptureSessionPresetMedium
        
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avSession)
        captureVideoPreviewLayer.frame = preview.bounds
        preview.layer.addSublayer(captureVideoPreviewLayer)
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            avSession.addInput(input)
            return avSession
        } catch let error as NSError {
            let title = error.userInfo["NSLocalizedDescription"] as! String
            let msg = error.userInfo["NSLocalizedFailureReason"] as! String
            
            showAlertWithTitle(title, andMessage: msg)
        }
        
        return nil
    }
    
    private func makePreviewViewWithPoint(point: CGPoint, andWidth width: CGFloat) -> UIView {
        let previewViewHeight = (width * 4.0) / 3.0
        let previewView = UIView(frame: CGRect(origin: point, size: CGSize(width: width, height: previewViewHeight)))
        
        previewView.backgroundColor = UIColor.blackColor()
        
        return previewView
    }
}

