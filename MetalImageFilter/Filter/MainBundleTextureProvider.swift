//
//  MainBundleTextureProvider.swift
//  imageprocessing01
//
//  Created by LEE CHUL HYUN on 5/11/18.
//  Copyright © 2018 LEE CHUL HYUN. All rights reserved.
//

import Foundation
import UIKit
import Metal

class MainBundleTextureProvider: GTextureProvider {
    var texture: MTLTexture!
    
    init(image: UIImage, context: GContext) {
        texture = self.texture(image: image, context: context)
    }
    
    func texture(image: UIImage, context: GContext) -> MTLTexture {
        let imageRef = image.cgImage
        let tempImage1 = UIImage.init(color: .green, size: CGSize(width: 4096, height: 4096)).cgImage
        var width = tempImage1!.width
        var height = tempImage1!.height
        let space = CGColorSpaceCreateDeviceRGB()
        var rawData = UnsafeMutableRawPointer.allocate(byteCount: width * height * 4, alignment: 1)// UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        let bytesPerPixel = 4
        var bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        var bitmmapContext = CGContext.init(data: rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |  CGImageByteOrderInfo.order32Big.rawValue)
//        bitmmapContext?.translateBy(x: 0, y: CGFloat(height))
//        bitmmapContext?.scaleBy(x: 1, y: -1)
        bitmmapContext?.draw(tempImage1!, in: CGRect.init(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        var textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: true)
        textureDescriptor.usage = [.shaderRead, .shaderWrite, .pixelFormatView]
        let texture = context.device.makeTexture(descriptor: textureDescriptor)
        var region = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow)
        rawData.deallocate()

        width = tempImage1!.width / 2
        height = tempImage1!.height / 2
        let tempImage = UIImage.init(color: .yellow, size: CGSize(width: width, height: height))
        rawData = UnsafeMutableRawPointer.allocate(byteCount: width * height * 4, alignment: 1)
        bytesPerRow = bytesPerPixel * width
        bitmmapContext = CGContext.init(data: rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |  CGImageByteOrderInfo.order32Big.rawValue)
        bitmmapContext?.draw(tempImage.cgImage!, in: CGRect.init(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        region = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 1, withBytes: rawData, bytesPerRow: bytesPerRow)
        rawData.deallocate()

        width = tempImage1!.width / 2 / 2
        height = tempImage1!.height / 2 / 2
        let tempImage2 = UIImage.init(color: .red, size: CGSize(width: width, height: height))
        rawData = UnsafeMutableRawPointer.allocate(byteCount: width * height * 4, alignment: 1)
        bytesPerRow = bytesPerPixel * width
        bitmmapContext = CGContext.init(data: rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |  CGImageByteOrderInfo.order32Big.rawValue)
        bitmmapContext?.draw(tempImage2.cgImage!, in: CGRect.init(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        region = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 2, withBytes: rawData, bytesPerRow: bytesPerRow)
        rawData.deallocate()

        return texture!
    }
    
    func provideTexture(textureBlock: (_ texture: MTLTexture?) -> Void) {
        textureBlock(self.texture)
    }
}
