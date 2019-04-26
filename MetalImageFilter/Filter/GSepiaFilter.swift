//
//  GSepiaFilter.swift
//  MetalImageFilter
//
//  Created by LEE CHUL HYUN on 4/15/19.
//  Copyright © 2019 LEE CHUL HYUN. All rights reserved.
//

import Foundation

class GSepiaFilter : GImageFilter {
    
    override init?(context: GContext) {
        
        super.init(functionName: "sepia", context: context)
    }
}
