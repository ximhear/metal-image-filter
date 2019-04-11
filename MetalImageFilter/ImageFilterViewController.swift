//
//  ImageFilterViewController.swift
//  imageprocessing02
//
//  Created by LEE CHUL HYUN on 5/12/18.
//  Copyright © 2018 LEE CHUL HYUN. All rights reserved.
//

import UIKit
import simd

class ImageFilterViewController: UIViewController {

    @IBOutlet weak var imageView:  UIImageView!
    @IBOutlet weak var saturationSlider:  UISlider!
    
    var context: GContext?
    var imageProvider: GTextureProvider?
    var desaturateFilter: GSaturationAdjustmentFilter?
    var blurFilter: GGaussianBlur2DFilter?
    var rotationFilter: GRotationFilter?
    var gbrFilter: GColorGBRFilter?
    var filterType: GImageFilterType = .colorGBR
    
    var renderingQueue: DispatchQueue?
    var jobIndex: UInt = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.renderingQueue = DispatchQueue.init(label: "Rendering")
        
        switch filterType {
        case .gaussianBlur2D:
            self.saturationSlider.value = 1
            self.saturationSlider.minimumValue = 1
            self.saturationSlider.maximumValue = 8
        case .saturationAdjustment:
            self.saturationSlider.value = 1
            self.saturationSlider.minimumValue = 0
            self.saturationSlider.maximumValue = 1
        case .colorGBR:
            self.saturationSlider.minimumValue = 0
            self.saturationSlider.maximumValue = 360
        case .rotation:
            self.saturationSlider.minimumValue = 0
            self.saturationSlider.maximumValue = 1
        }
        
        buildFilterGraph()
        updateImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func blurChanged(_ sender: Any) {
        updateImage()
    }
    
    @IBAction func saturationChanged(_ sender: Any) {
        updateImage()
    }
    
    func buildFilterGraph() {
        self.context = GContext()
        
        self.imageProvider = MainBundleTextureProvider.init(imageName: "autumn", context: self.context!)

        self.rotationFilter = GRotationFilter.init(context: self.context!)
        self.rotationFilter?.provider = self.imageProvider!
        

        self.desaturateFilter = GSaturationAdjustmentFilter.init(saturationFactor: self.saturationSlider.value, context: self.context!)
        self.desaturateFilter?.provider = self.imageProvider
        
        self.blurFilter = GGaussianBlur2DFilter.init(radius: self.saturationSlider.value, context: self.context!)
        self.blurFilter?.provider = self.imageProvider
        
        self.gbrFilter = GColorGBRFilter(context: self.context!)
        self.gbrFilter?.provider = self.imageProvider
    }
    
    func updateImage() {
        jobIndex += 1
        let currentJobIndex: UInt = self.jobIndex
        
        // Grab these values while we're still on the main thread, since we could
        // conceivably get incomplete values by reading them in the background.
        let saturation: Float = self.saturationSlider.value
        
        renderingQueue?.async {[weak self] in
            guard let welf = self else {
                return
            }
            if currentJobIndex != self?.jobIndex {
                return
            }
            
            let filter: GImageFilter?
            switch welf.filterType {
            case .gaussianBlur2D:
                self?.blurFilter?.radius = saturation
                filter = self?.blurFilter
            case .saturationAdjustment:
                self?.desaturateFilter?.saturationFactor = saturation
                filter = self?.desaturateFilter
            case .rotation:
                self?.rotationFilter?.factor = saturation
                filter = self?.rotationFilter
            case .colorGBR:
                self?.gbrFilter?.rotation = saturation
                filter = self?.gbrFilter
            }
            
            let texture = filter?.texture
            let image = UIImage.init(texture: texture)
            
            DispatchQueue.main.async {[weak self] in
                self?.imageView.image = image
            }
        }
    }
}

