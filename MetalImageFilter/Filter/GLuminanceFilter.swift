//
//  GLuminanceFilter.swift
//  MetalImageFilter
//
//  Created by LEE CHUL HYUN on 4/23/19.
//  Copyright © 2019 LEE CHUL HYUN. All rights reserved.
//

import UIKit

class GLuminanceFilter: GImageFilter {

    init?(context: GContext) {
        
        super.init(functionName: "luminance", context: context)
    }
}
