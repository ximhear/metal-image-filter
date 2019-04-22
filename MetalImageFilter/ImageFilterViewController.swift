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
    @IBOutlet weak var containerView: UIView!
    
    var imageProvider: GTextureProvider?
    var imageFilter: GImageFilter?
    var filterType: GImageFilterType = .colorGBR
    var imageChanged: (_ image: UIImage) -> Void = {_ in }
    var image: UIImage!
    
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
        case .sepia:
            containerView.isHidden = true
        case .pixellation:
            self.saturationSlider.value = 1
            self.saturationSlider.minimumValue = 1
            self.saturationSlider.maximumValue = 300
        case .luminance:
            containerView.isHidden = true
        case .normalMap:
            containerView.isHidden = true
        }
        self.title = filterType.name
        
        buildFilterGraph(image: self.image)
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
    
    func buildFilterGraph(image: UIImage) {
        let context = GContext()
        
        self.imageProvider = MainBundleTextureProvider.init(image: image, context: context)

        self.imageFilter = filterType.createImageFilter(context: context)
        self.imageFilter?.provider = self.imageProvider!
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
            
            let filter: GImageFilter? = welf.imageFilter
            filter?.setValue(saturation)
            
            let texture = filter?.texture
            let image = UIImage.init(texture: texture)
            
            DispatchQueue.main.async {[weak self] in
                self?.imageView.image = image
            }
        }
    }
    
    @IBAction func albumClicked(_ sender: Any) {
        GZLogFunc()
    }
    
    @IBAction func cameraClicked(_ sender: Any) {
        GZLogFunc()
        
        if let vc = storyboard?.instantiateViewController(withIdentifier: "PhotoViewController") as? PhotoViewController {
            vc.imageCaptured = { [weak self] (image) in
                self?.imageChanged(image)
                self?.image = image
                self?.buildFilterGraph(image: image)
                self?.updateImage()
            }
            present(vc, animated: true) {
            }
        }
    }
}

