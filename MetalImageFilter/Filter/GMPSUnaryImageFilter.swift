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

    init?(type: GMPSUnaryImageFilterType, context: GContext, filterType: GImageFilterType) {
        self.type = type
        super.init(context: context, filterType: filterType)
    }
    
    override func encode(input: inout MTLTexture, output: MTLTexture, commandBuffer: MTLCommandBuffer) {
        
        switch type {
        case .sobel:
            sobel(input, output, commandBuffer)
        case .gaussianBlur:
            gaussianBlur(input, output, commandBuffer)
        case .gaussianPyramid:
            gaussianPyramid(&input, output, commandBuffer)
        case .laplacianPyramid:
            laplacianPyramid(&input, output, commandBuffer)
        }
    }
    
    override var texture: MTLTexture? {
        
        GZLogFunc(_value)
        if filterType.outputMipmapped == false {
            return super.texture
        }
        
        guard let texture = super.texture else {
            return nil
        }
        let mipmapLevel = Int(_value)
        let divider = pow(2, Double(mipmapLevel))
        let width = Int(max(1, floor(Double(texture.width) / divider)))
        let height = Int(max(1, floor(Double(texture.height) / divider)))
        GZLogFunc(width)
        GZLogFunc(height)

        let rawData = UnsafeMutableRawPointer.allocate(byteCount: width * height * 4, alignment: 1)// UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        texture.getBytes(rawData, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: mipmapLevel)
        
        let textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        textureDescriptor.usage = .shaderRead
        
        let t = context.device.makeTexture(descriptor: textureDescriptor)
        let region = MTLRegionMake2D(0, 0, width, height)
        t?.replace(region: region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow)
        rawData.deallocate()

        return t!
    }
    
    func sobel(_ input: MTLTexture, _ output: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        let shader = MPSImageSobel(device: context.device)
        shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: output)
    }
    
    func gaussianBlur(_ input: MTLTexture, _ output: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        let shader = MPSImageGaussianBlur(device: context.device, sigma: _value)
        shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: output)
    }
    
    func gaussianPyramid(_ input: inout MTLTexture, _ output: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        
        let shader = MPSImageGaussianPyramid(device: context.device , centerWeight: 0.375)
//        let shader = MPSImageGaussianPyramid(device: context.device, kernelWidth: 5, kernelHeight: 5, weights: [0.2, 0.2, 0.2, 0.2, 0.2])
        _ = shader.encode(commandBuffer: commandBuffer, inPlaceTexture: &input, fallbackCopyAllocator: nil)
    }
    
    func laplacianPyramid(_ input: inout MTLTexture, _ output: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        
        let shader = MPSImageLaplacianPyramid(device: context.device)// , centerWeight: 0.375)
        GZLogFunc(shader.laplacianBias)
        GZLogFunc(shader.laplacianScale)
//        let shader = MPSImageLaplacianPyramid(device: context.device, kernelWidth: 3, kernelHeight: 3, weights: [0, 1, 0, 1, -4, 1, 0, 1, 0])
        shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: output)
//        _ = shader.encode(commandBuffer: commandBuffer, inPlaceTexture: &input, fallbackCopyAllocator: nil)
        GZLogFunc(output.mipmapLevelCount)
    }
}
