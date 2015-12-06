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

class ViewController: UIViewController {
    let locationManager = CLLocationManager()
    
    var avSession: AVCaptureSession!
    var previewView: UIView!
    var arManager: ARManager!
    var infiniteScrollView: InfiniteScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewView = makePreviewViewWithPoint(CGPoint(x: 0, y: 0), andWidth: view.frame.width)
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        avSession = setupCameraPreviewWithPreview(previewView, andDevice: device)
        
        infiniteScrollView = InfiniteScrollView(frame: previewView.frame, cameraFieldOfView: Double(device.activeFormat.videoFieldOfView))
        arManager = ARManager(infiniteScrollView: infiniteScrollView)
        
        view.addSubview(previewView)
        view.addSubview(infiniteScrollView)
        
        locationManager.delegate = arManager
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        avSession.startRunning()
        locationManager.startUpdatingHeading()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        avSession.stopRunning()
        locationManager.stopUpdatingHeading()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    private func setupCameraPreviewWithPreview(preview: UIView, andDevice device: AVCaptureDevice) -> AVCaptureSession {
        let avSession = AVCaptureSession()
        avSession.sessionPreset = AVCaptureSessionPresetMedium
        
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avSession)
        captureVideoPreviewLayer.frame = preview.bounds
        preview.layer.addSublayer(captureVideoPreviewLayer)
        
        let input = try! AVCaptureDeviceInput(device: device)
        
        avSession.addInput(input)
        
        return avSession
    }
    
    private func makePreviewViewWithPoint(point: CGPoint, andWidth width: CGFloat) -> UIView {
        let previewViewHeight = (width * 4.0) / 3.0
        let previewView = UIView(frame: CGRect(origin: point, size: CGSize(width: width, height: previewViewHeight)))
        
        previewView.backgroundColor = UIColor.blackColor()
        
        return previewView
    }
}

