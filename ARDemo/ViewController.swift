//
//  ViewController.swift
//  ARDemo
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
        
        view.backgroundColor = UIColor.black
        
        previewView = makePreviewViewWithPoint(CGPoint(x: 0, y: 0), andWidth: view.frame.width)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setup()

        // Cracow Old Town, Poland
        let location_one = CLLocation(latitude: 50.0611958, longitude: 19.9379069)

        // Leaning Tower of Pisa, Italy
        let location_two = CLLocation(latitude: 43.722952, longitude: 10.3944083)

        // Acropolis of Athens, Greek
        let location_three = CLLocation(latitude: 37.971421, longitude: 23.726166)

        // Eiffel Tower, French
        let location_four = CLLocation(latitude: 48.858222, longitude: 2.2945)

        // Big Ben, UK
        let location_five = CLLocation(latitude: 51.5007292, longitude: -0.1268124)
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
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
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    fileprivate func showAlertWithTitle(_ title: String, andMessage msg: String) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        let okAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        alertController.addAction(okAlertAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func showAlertAboutNoPermissionForGps() {
        showAlertWithTitle(NSLocalizedString("Cannot use GPS", comment: ""), andMessage: NSLocalizedString("This app is not authorized to use GPS", comment: ""))
    }
    
    // MARK: - setup functions
    fileprivate func setup() {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        avSession = setupCameraPreviewWithPreview(previewView, andDevice: device!)
        
        infiniteScrollView = InfiniteScrollView(frame: previewView.frame, cameraFieldOfView: Double((device?.activeFormat.videoFieldOfView)!))
        arManager = ARManager(infiniteScrollView: infiniteScrollView)
        
        view.addSubview(previewView)
        view.addSubview(infiniteScrollView)
        
        setupLocationManager()
        setupMessageLabel()
        setupMotionManager()
    }
    
    fileprivate func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            let queue = OperationQueue.main
            motionManager.startDeviceMotionUpdates(to: queue, withHandler: { (motion, error) in
                if (error == nil) {
                    if let motion = motion {
                        let x = motion.gravity.x
                        let z = motion.gravity.z

                        DispatchQueue.main.async { () -> Void in
                            if fabs(x) > 0.45 {
                                self.lblMessage.isHidden = false
                                self.infiniteScrollView.isHidden = true
                                self.lblMessage.text = NSLocalizedString("You lose precision when phone is tilted", comment: "")
                            } else if fabs(z) > 0.50 {
                                self.lblMessage.isHidden = false
                                self.infiniteScrollView.isHidden = true
                                self.lblMessage.text = NSLocalizedString("There's nothing there. Try to look straight", comment: "")
                            } else {
                                self.lblMessage.isHidden = true
                                self.infiniteScrollView.isHidden = false
                            }
                        }
                    }
                }
            })
        }
    }
    
    fileprivate func setupLocationManager() {
        locationManager.delegate = arManager
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            showAlertAboutNoPermissionForGps()
        default:
            break
        }
    }
    
    fileprivate func setupMessageLabel() {
        lblMessage = UILabel(frame: CGRect(x: 0, y: 0, width: previewView.frame.width, height: previewView.frame.height / 3))
        lblMessage.center.y = previewView.center.y
        lblMessage.font = UIFont.boldSystemFont(ofSize: 40)
        lblMessage.numberOfLines = 0
        lblMessage.textAlignment = .center
        lblMessage.backgroundColor = UIColor.gray
        lblMessage.isHidden = true
        previewView.addSubview(lblMessage)
    }

    fileprivate func setupCameraPreviewWithPreview(_ preview: UIView, andDevice device: AVCaptureDevice) -> AVCaptureSession? {
        let avSession = AVCaptureSession()
        avSession.sessionPreset = AVCaptureSessionPresetMedium
        
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avSession)
        captureVideoPreviewLayer?.frame = preview.bounds
        preview.layer.addSublayer(captureVideoPreviewLayer!)
        
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
    
    fileprivate func makePreviewViewWithPoint(_ point: CGPoint, andWidth width: CGFloat) -> UIView {
        let previewViewHeight = (width * 4.0) / 3.0
        let previewView = UIView(frame: CGRect(origin: point, size: CGSize(width: width, height: previewViewHeight)))
        
        previewView.backgroundColor = UIColor.black
        
        return previewView
    }
}

