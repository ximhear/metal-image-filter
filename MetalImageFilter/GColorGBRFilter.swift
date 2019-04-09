//
//  GColorGBRFilter.swift
//  MetalImageFilter
//
//  Created by LEE CHUL HYUN on 4/10/19.
//  Copyright © 2019 LEE CHUL HYUN. All rights reserved.
//

import Foundation
import Metal

class GColorGBRFilter: GImageFilter {
    
    init?(context: GContext) {
        super.init(functionName: "gbr", context: context)
    }
}
