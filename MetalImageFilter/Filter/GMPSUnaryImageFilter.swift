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
    
    override func encode(input: inout MTLTexture, tempOutput: MTLTexture?, finalOutput: MTLTexture, commandBuffer: MTLCommandBuffer) {
        
        switch type {
        case .sobel:
            sobel(input, finalOutput, commandBuffer)
        case .laplacian:
            laplacian(input, tempOutput, finalOutput, commandBuffer)
        case .gaussianBlur:
            gaussianBlur(input, finalOutput, commandBuffer)
        case .gaussianPyramid:
            gaussianPyramid(&input, finalOutput, commandBuffer)
        case .laplacianPyramid:
            laplacianPyramid(&input, tempOutput, finalOutput, commandBuffer)
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
    
    func laplacian(_ input: MTLTexture, _ tempOutput: MTLTexture?, _ finalOutput: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
//        let shader = MPSImageConvolution(device: context.device, kernelWidth: 3, kernelHeight: 3, weights: [1,2,1,2,4,2,1,2,1])
//        let shader = MPSImageConvolution(device: context.device, kernelWidth: 3, kernelHeight: 3, weights: [0, 1, 0, 1, -4, 1, 0, 1, 0])
//        let shader = MPSImageConvolution(device: context.device, kernelWidth: 3, kernelHeight: 3, weights: [1, 1, 1, 1, -8, 1, 1, 1, 1])
        let shader = MPSImageLaplacian(device: context.device)
//        shader.bias = 0.1
        if let o = tempOutput {
//            let sobel = MPSImageSobel(device: context.device)
//            sobel.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: o)
//            shader.encode(commandBuffer: commandBuffer, sourceTexture: o, destinationTexture: finalOutput)
            
            shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: o)
            let threshold = MPSImageThresholdBinary(device: context.device, thresholdValue: 0.02, maximumValue: 1, linearGrayColorTransform: nil)
            threshold.encode(commandBuffer: commandBuffer, sourceTexture: o, destinationTexture: finalOutput)
        }
        else {
            shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: finalOutput)
        }
//        _ = shader.encode(commandBuffer: commandBuffer, inPlaceTexture: &output, fallbackCopyAllocator: nil)
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
    
    func laplacianPyramid(_ input: inout MTLTexture, _ tempOutput: MTLTexture?, _ finalOutput: MTLTexture, _ commandBuffer: MTLCommandBuffer) {
        
        let shader = MPSImageLaplacianPyramid(device: context.device)// , centerWeight: 0.375)
//        shader.laplacianBias = 0.5
        GZLogFunc(shader.laplacianBias)
        GZLogFunc(shader.laplacianScale)

        if let o = tempOutput {
            
            shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: o)
            let threshold = MPSImageThresholdBinary(device: context.device, thresholdValue: 0.02, maximumValue: 1, linearGrayColorTransform: nil)
            threshold.encode(commandBuffer: commandBuffer, sourceTexture: o, destinationTexture: finalOutput)
        }
        else {
            let gaussian = MPSImageGaussianPyramid(device: context.device , centerWeight: 0.375)
            _ = gaussian.encode(commandBuffer: commandBuffer, inPlaceTexture: &input, fallbackCopyAllocator: nil)
            
//            _ = shader.encode(commandBuffer: commandBuffer, inPlaceTexture: &input, fallbackCopyAllocator: nil)
            shader.encode(commandBuffer: commandBuffer, sourceTexture: input, destinationTexture: finalOutput)
        }
    }
}
