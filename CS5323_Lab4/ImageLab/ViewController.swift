//
//  ViewController.swift
//  ImageLab
//
//  Created by Jason Brown
//  Copyright © Jason Brown. All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit

class ViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VisionAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    @IBOutlet weak var stageLabel: UILabel!
    @IBOutlet weak var cameraView: MTKView!
    
    @IBOutlet weak var switchCamera: UIButton!
    @IBOutlet weak var flash: UIButton!
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        
        self.videoManager = VisionAnalgesic(view: self.cameraView)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
        let device = AVCaptureDevice.default(for: AVMediaType.video)
    
    }
    
    //MARK: Process image output
    func processImageSwift(inputImage:CIImage) -> CIImage{
        
        
        var retImage = inputImage
        
       
        //-------------------Example 2----------------------------------
        // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCV
        // this is a BLOCKING CALL
        
        // FOR FLIPPED ASSIGNMENT, YOU MAY BE INTERESTED IN THIS EXAMPLE
        
        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        lazy var ret = self.bridge.processFinger()
        print(self.bridge.processFinger)
            
        retImage = self.bridge.getImage()
        
        
        //setting buttons default values while in this function
        flash.isEnabled = true
        switchCamera.isEnabled = true

        
        if(ret == true)
        {
            //If there is feature, capture RGB array over 100 frames and saved average RGB values
            //in array when captured print something to cv:putText.
            //Disable camera toggle and torch toggle
            
            print("\(ret)")
        
            do{
                try self.videoManager.turnOnFlashwithLevel(2)
                
                AVCaptureDevice.TorchMode.on
                if(Conditionals.cflag == 0){
                    Conditionals.cflag = 1
                    self.videoManager.toggleFlash()
                }
            }
                    catch{
                        print("Torch can't be used")
                    }
                
            
            //Disable camera toggle and torch toggle
            flash.isEnabled = false
            switchCamera.isEnabled = false
            
        }
        
        //Check if toggleflash was left on and turn off if so
        if (ret != true && Conditionals.cflag ==  1){
            Conditionals.cflag = 0
            self.videoManager.turnOffFlash()

        }
            retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)
            
            return retImage
        
        
        }
    //Setup conditional to regulate use of torch
    struct Conditionals {
        static var cflag : Int = 0
    }
    
    
    //MARK: Convenience Methods for UI Flash and Camera Toggle
    @IBAction func flash(_ sender: AnyObject) {
       
        if(self.videoManager.toggleFlash()){
            
            self.flashSlider.value = 1.0
        }
        else{
            Conditionals.cflag = 0
            self.flashSlider.value = 0.0
        }
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    
    @IBAction func setFlashLevel(_ sender: UISlider) {
        if(sender.value>0.0){
            let val = self.videoManager.turnOnFlashwithLevel(sender.value)
            if val {
                print("Flash return, no errors.")
            }
        }
        else if(sender.value==0.0){
            self.videoManager.turnOffFlash()
        }
    }

   
}

