//
//  GImageFilter.swift
//  imageprocessing01
//
//  Created by chlee on 11/05/2018.
//  Copyright © 2018 LEE CHUL HYUN. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders

protocol GFilterValueSetter {
    
    func setValue(_ value: Float)
}

class GImageFilter: GTextureProvider, GTextureConsumer, GFilterValueSetter {
    
    var context: GContext
    var uniformBuffer: MTLBuffer?
    var pipeline: MTLComputePipelineState!
    var isDirty: Bool = true
    var kernelFunction: MTLFunction?
    var texture: MTLTexture! {
        if self.isDirty {
            self.applyFilter()
        }
        return self.internalTexture
    }
    var provider: GTextureProvider!
    var internalTexture: MTLTexture?

    init(functionName: String, context: GContext) {
        self.context = context
        self.kernelFunction = self.context.library.makeFunction(name: functionName)
        self.pipeline = try! self.context.device.makeComputePipelineState(function: self.kernelFunction!)
    }

    init?(context: GContext) {
        self.context = context
    }

    func configureArgumentTable(commandEncoder: MTLComputeCommandEncoder) {
    }
    
    func setValue(_ value: Float) {
    }
    
    func applyFilter() {
        var inputTexture = self.provider.texture!
        GZLogFunc(inputTexture)
        if self.internalTexture == nil ||
            self.internalTexture!.width != inputTexture.width ||
            self.internalTexture!.height != inputTexture.height {
            GZLogFunc("pixel format : \(inputTexture.pixelFormat.rawValue)")
            GZLogFunc("width : \(inputTexture.width)")
            GZLogFunc("height : \(inputTexture.height)")
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat, width: inputTexture.width, height: inputTexture.height, mipmapped: true)
            textureDescriptor.usage = MTLTextureUsage.init(rawValue: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue)
            self.internalTexture = self.context.device.makeTexture(descriptor: textureDescriptor)
        }
        
        if let commandBuffer = self.context.commandQueue.makeCommandBuffer(), let _ = internalTexture {
            
            let output: MTLTexture = internalTexture!
            
            let result = encode(input: &inputTexture, output: output, commandBuffer: commandBuffer)
            if result == true {
                GZLogFunc("\(output.width) x \(output.height)")
                
                let width = inputTexture.width / 2 / 2
                let height = inputTexture.height / 2 / 2
                
                let rawData = UnsafeMutableRawPointer.allocate(byteCount: width * height * 4, alignment: 1)// UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
                let bytesPerPixel = 4
                let bytesPerRow = bytesPerPixel * width
                inputTexture.getBytes(rawData, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 2)

                let textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
                textureDescriptor.usage = .shaderRead
                
                let texture = context.device.makeTexture(descriptor: textureDescriptor)
                let region = MTLRegionMake2D(0, 0, width, height)
                texture?.replace(region: region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow)
                rawData.deallocate()
                internalTexture = texture
            }
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        GZLogFunc()
    }
    
    func encode(input: inout MTLTexture, output: MTLTexture, commandBuffer: MTLCommandBuffer) -> Bool {
        GZLogFunc("threadExecutionWidth: \(pipeline.threadExecutionWidth)")
        GZLogFunc("maxTotalThreadsPerThreadgroup: \(pipeline.maxTotalThreadsPerThreadgroup)")
        
        let threadgroupCounts = MTLSizeMake(pipeline.threadExecutionWidth, pipeline.maxTotalThreadsPerThreadgroup/pipeline.threadExecutionWidth, 1)
        //        let threadgroupCounts = MTLSizeMake(8, 8, 1)
        let threadgroups = MTLSizeMake(input.width / threadgroupCounts.width, input.height / threadgroupCounts.height, 1)
        
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(self.pipeline)
        commandEncoder?.setTexture(input, index: 0)
        commandEncoder?.setTexture(output, index: 1)
        GZLogFunc("\(input.width), \(input.height)")
        GZLogFunc("\(output.width), \(output.height)")
        self.configureArgumentTable(commandEncoder: commandEncoder!)
        //        if #available(iOS 11.0, *) {
        //            commandEncoder?.dispatchThreads(MTLSizeMake(inputTexture.width, inputTexture.height, 1), threadsPerThreadgroup: threadgroupCounts)
        //        } else {
        commandEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        //        }
        commandEncoder?.endEncoding()
        
        return false
    }
    
}
