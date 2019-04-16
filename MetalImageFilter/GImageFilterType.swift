//
//  GImageFilterType.swift
//  MetalImageFilter
//
//  Created by LEE CHUL HYUN on 4/15/19.
//  Copyright © 2019 LEE CHUL HYUN. All rights reserved.
//

import Foundation

enum GImageFilterType {
    case gaussianBlur2D
    case saturationAdjustment
    case rotation
    case colorGBR
    case sepia
    case pixellation
    
    var name: String {
        switch self {
        case .gaussianBlur2D:
            return "gaussianBlur2D"
        case .saturationAdjustment:
            return "saturationAdjustment"
        case .rotation:
            return "rotation"
        case .colorGBR:
            return "colorGBR"
        case .sepia:
            return "sepia"
        case .pixellation:
            return "pixellation"
        }
    }
    
    func createImageFilter(context: GContext) -> GImageFilter? {
        
        switch self {
        case .gaussianBlur2D:
            return GGaussianBlur2DFilter(context: context)
        case .saturationAdjustment:
            return GSaturationAdjustmentFilter(context: context)
        case .rotation:
            return GRotationFilter(context: context)
        case .colorGBR:
            return GColorGBRFilter(context: context)
        case .sepia:
            return GSepiaFilter(context: context)
        case .pixellation:
            return GPixellationFilter(context: context)
        }
    }
}

