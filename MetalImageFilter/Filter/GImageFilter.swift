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
    var texture: MTLTexture? {
        if self.isDirty {
            self.applyFilter()
        }
        return self.internalTexture
    }
    var provider: GTextureProvider!
    var internalTexture: MTLTexture?
    var internalTexture2: MTLTexture?
    let filterType: GImageFilterType

    init(functionName: String, context: GContext, filterType: GImageFilterType) {
        self.context = context
        self.filterType = filterType
        self.kernelFunction = self.context.library.makeFunction(name: functionName)
        self.pipeline = try! self.context.device.makeComputePipelineState(function: self.kernelFunction!)
    }

    init?(context: GContext, filterType: GImageFilterType) {
        self.context = context
        self.filterType = filterType
    }

    func configureArgumentTable(commandEncoder: MTLComputeCommandEncoder) {
    }
    
    func setValue(_ value: Float) {
    }
    
    func applyFilter() {
        var inputTexture = self.provider.texture!
        GZLogFunc(inputTexture)
        if self.filterType.inPlaceTexture == false {
            if self.internalTexture == nil ||
                self.internalTexture!.width != inputTexture.width ||
                self.internalTexture!.height != inputTexture.height {
                GZLogFunc("pixel format : \(inputTexture.pixelFormat.rawValue)")
                GZLogFunc("width : \(inputTexture.width)")
                GZLogFunc("height : \(inputTexture.height)")
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat, width: inputTexture.width, height: inputTexture.height, mipmapped: self.filterType.outputMipmapped)
                textureDescriptor.usage = MTLTextureUsage.init(rawValue: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue)
                self.internalTexture = self.context.device.makeTexture(descriptor: textureDescriptor)
            }
        }
        else {
            internalTexture = inputTexture
        }
        
        if self.filterType.output2Required == true {
            if self.internalTexture2 == nil ||
                self.internalTexture2!.width != inputTexture.width ||
                self.internalTexture2!.height != inputTexture.height {
                GZLogFunc("pixel format : \(inputTexture.pixelFormat.rawValue)")
                GZLogFunc("width : \(inputTexture.width)")
                GZLogFunc("height : \(inputTexture.height)")
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: inputTexture.pixelFormat, width: inputTexture.width, height: inputTexture.height, mipmapped: self.filterType.outputMipmapped)
                textureDescriptor.usage = MTLTextureUsage.init(rawValue: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue)
                self.internalTexture2 = self.context.device.makeTexture(descriptor: textureDescriptor)
            }
        }
        
        if let commandBuffer = self.context.commandQueue.makeCommandBuffer(), let _ = internalTexture {
            
            let output: MTLTexture = internalTexture!
            let output2: MTLTexture? = internalTexture2

            encode(input: &inputTexture, tempOutput: output2, finalOutput: output, commandBuffer: commandBuffer)

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            if self.filterType.inPlaceTexture == true {
                GZLogFunc("\(inputTexture.width) x \(inputTexture.height)")
                internalTexture = inputTexture
            }
            GZLogFunc()
        }
        GZLogFunc()
    }
    
    func encode(input: inout MTLTexture, tempOutput: MTLTexture?, finalOutput: MTLTexture, commandBuffer: MTLCommandBuffer) {
        GZLogFunc("threadExecutionWidth: \(pipeline.threadExecutionWidth)")
        GZLogFunc("maxTotalThreadsPerThreadgroup: \(pipeline.maxTotalThreadsPerThreadgroup)")
        
        let threadgroupCounts = MTLSizeMake(pipeline.threadExecutionWidth, pipeline.maxTotalThreadsPerThreadgroup/pipeline.threadExecutionWidth, 1)
        //        let threadgroupCounts = MTLSizeMake(8, 8, 1)
        let threadgroups = MTLSizeMake(input.width / threadgroupCounts.width, input.height / threadgroupCounts.height, 1)
        
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(self.pipeline)
        commandEncoder?.setTexture(input, index: 0)
        commandEncoder?.setTexture(finalOutput, index: 1)
        GZLogFunc("\(input.width), \(input.height)")
        GZLogFunc("\(finalOutput.width), \(finalOutput.height)")
        self.configureArgumentTable(commandEncoder: commandEncoder!)
        //        if #available(iOS 11.0, *) {
        //            commandEncoder?.dispatchThreads(MTLSizeMake(inputTexture.width, inputTexture.height, 1), threadsPerThreadgroup: threadgroupCounts)
        //        } else {
        commandEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        //        }
        commandEncoder?.endEncoding()
    }
    
}
