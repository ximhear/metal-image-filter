//
//  GMPSUnaryImageFilterType.swift
//  MetalImageFilter
//
//  Created by gzonelee on 26/04/2019.
//  Copyright © 2019 LEE CHUL HYUN. All rights reserved.
//

import Foundation

enum GMPSUnaryImageFilterType {
    case sobel
    case gaussianBlur
    case gaussianPyramid
    
    var name: String {
        switch self {
        case .sobel:
            return "MPS Sobel"
        case .gaussianBlur:
            return "MPS GaussianBlur"
        case .gaussianPyramid:
            return "MPS GaussianPyramid"
        }
    }
}

