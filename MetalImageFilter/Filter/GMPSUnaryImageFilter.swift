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
    
    override func encode(input: MTLTexture, output: inout MTLTexture, commandBuffer: MTLCommandBuffer) -> Bool {
        
        switch type {
        case .sobel:
            sobel(input, output, commandBuffer)
        case .gaussianBlur:
            gaussianBlur(input, output, commandBuffer)
        case .gaussianPyramid:
            return gaussianPyramid(input, &output, commandBuffer)
        }
        return false
    }
    
    func sobel(_ input: MTLTexture, _ output: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        let shader = MPSImageSobel(device: context.device)
        shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: output)
    }
    
    func gaussianBlur(_ input: MTLTexture, _ output: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        let shader = MPSImageGaussianBlur(device: context.device, sigma: _value)
        shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: output)
    }
    
    func gaussianPyramid(_ input: MTLTexture, _ output: inout MTLTexture, _ commandBuffer: MTLCommandBuffer) -> Bool {
        
        let shader = MPSImageGaussianPyramid(device: context.device, centerWeight: 0.375)
//        let shader = MPSImageGaussianBlur(device: context.device, sigma: _value)

        let inPlaceTexture = UnsafeMutablePointer<MTLTexture>.allocate(capacity: 1)
        inPlaceTexture.initialize(to: input)
//        var iii: MTLTexture? = input
        let r = shader.encode(commandBuffer: commandBuffer, inPlaceTexture: inPlaceTexture, fallbackCopyAllocator: nil)
        GZLogFunc(r)
        output = inPlaceTexture.pointee
        GZLogFunc(input.mipmapLevelCount)
        GZLogFunc(output.mipmapLevelCount)
        GZLogFunc()
//        shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: output)
        return true
    }
}

extension MTLTexture {
    /// Utility function for building a descriptor that matches this texture
    func matchingDescriptor() -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = self.textureType
        // NOTE: We should be more careful to select a renderable pixel format here,
        // especially if operating on a compressed texture.
        descriptor.pixelFormat = self.pixelFormat
        descriptor.width = self.width
        descriptor.height = self.height
        descriptor.depth = self.depth
        descriptor.mipmapLevelCount = self.mipmapLevelCount
        descriptor.arrayLength = self.arrayLength
        // NOTE: We don't set resourceOptions here, since we explicitly set cache and storage modes below.
        descriptor.cpuCacheMode = self.cpuCacheMode
        descriptor.storageMode = self.storageMode
        descriptor.usage = self.usage
        return descriptor
    }
}
