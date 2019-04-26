//
//  GMPSUnaryImageFilter.swift
//  MetalImageFilter
//
//  Created by gzonelee on 26/04/2019.
//  Copyright © 2019 LEE CHUL HYUN. All rights reserved.
//

import UIKit
import Metal
import MetalPerformanceShaders

class GMPSUnaryImageFilter: GImageFilter {
    
    var _value: Float = 0
    override func setValue(_ value: Float) {
        _value = value
        self.isDirty = true
    }

    let type: GMPSUnaryImageFilterType

    init?(type: GMPSUnaryImageFilterType, context: GContext) {
        self.type = type
        super.init(context: context)
    }
    
    override func encode(input: MTLTexture, output: MTLTexture, commandBuffer: MTLCommandBuffer) {
        
        switch type {
        case .sobel:
            sobel(input, output, commandBuffer)
        case .gaussianBlur:
            gaussianBlur(input, output, commandBuffer)
        }
    }
    
    func sobel(_ input: MTLTexture, _ output: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        let shader = MPSImageSobel(device: context.device)
        shader.encode(commandBuffer: commandBuffer, sourceTexture: input,
                      destinationTexture: output)
    }
    
    func gaussianBlur(_ input: MTLTexture, _ output: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        let shader = MPSImageGaussianBlur(device: context.device, sigma: _value)
        shader.encode(commandBuffer: commandBuffer, sourceTexture: input,
                      destinationTexture: output)
    }
}
