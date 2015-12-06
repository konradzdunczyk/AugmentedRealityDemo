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
    var lblMessage: UILabel!
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
        let location_three = CLLocation(latitude: 51.771381, longitude: 22.630652)
        let location_four = CLLocation(latitude: 53.541212, longitude: 20.721804)
        let location_five = CLLocation(latitude: 50.548096, longitude: 21.171050)
        
        arManager.addLocation(location_one)
        arManager.addLocation(location_two)
        arManager.addLocation(location_three)
        arManager.addLocation(location_four)
        arManager.addLocation(location_five)
        
        locationManager.startUpdatingHeading()
        
        if let avSession = avSession {
            avSession.startRunning()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let avSession = avSession {
            avSession.stopRunning()
        }
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
        showAlertWithTitle(NSLocalizedString("Cannot use GPS", comment: ""), andMessage: NSLocalizedString("This app is not authorized to use GPS", comment: ""))
    }
    
    // MARK: - setup functions
    private func setup() {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        avSession = setupCameraPreviewWithPreview(previewView, andDevice: device)
        
        infiniteScrollView = InfiniteScrollView(frame: previewView.frame, cameraFieldOfView: Double(device.activeFormat.videoFieldOfView))
        arManager = ARManager(infiniteScrollView: infiniteScrollView)
        
        view.addSubview(previewView)
        view.addSubview(infiniteScrollView)
        
        setupLocationManager()
        setupMessageLabel()
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            let queue = NSOperationQueue.mainQueue()
            motionManager.startDeviceMotionUpdatesToQueue(queue, withHandler: { (motion: CMDeviceMotion?, error: NSError?) -> Void in
                if (error == nil) {
                    if let motion = motion {
                        let x = motion.gravity.x
                        let z = motion.gravity.z
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if fabs(x) > 0.45 {
                                self.lblMessage.hidden = false
                                self.infiniteScrollView.hidden = true
                                self.lblMessage.text = NSLocalizedString("You lose precision when phone is tilted", comment: "")
                            } else if fabs(z) > 0.50 {
                                self.lblMessage.hidden = false
                                self.infiniteScrollView.hidden = true
                                self.lblMessage.text = NSLocalizedString("There's nothing there. Try to look straight", comment: "")
                            } else {
                                self.lblMessage.hidden = true
                                self.infiniteScrollView.hidden = false
                            }
                        })
                    }
                }
            })
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = arManager
        
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
    
    private func setupMessageLabel() {
        lblMessage = UILabel(frame: CGRect(x: 0, y: 0, width: previewView.frame.width, height: previewView.frame.height / 3))
        lblMessage.center.y = previewView.center.y
        lblMessage.font = UIFont.boldSystemFontOfSize(40)
        lblMessage.numberOfLines = 0
        lblMessage.textAlignment = .Center
        lblMessage.backgroundColor = UIColor.grayColor()
        lblMessage.hidden = true
        previewView.addSubview(lblMessage)
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

