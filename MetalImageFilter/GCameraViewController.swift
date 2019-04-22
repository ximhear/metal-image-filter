//
//  GCameraViewController.swift
//  MetalImageFilter
//
//  Created by LEE CHUL HYUN on 4/23/19.
//  Copyright © 2019 LEE CHUL HYUN. All rights reserved.
//

import UIKit
import CameraKit_iOS

class GCameraViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Init a photo capture session
        let session = CKFPhotoSession()
        
        // Use CKFVideoSession for video capture
        // let session = CKFVideoSession()
        
        let previewView = CKFPreviewView(frame: self.view.bounds)
        previewView.session = session
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
