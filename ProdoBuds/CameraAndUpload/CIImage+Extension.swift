//
//  CIImage+Extension.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/6/26.
//

import CoreImage

extension CIImage {
    
    var cgImage: CGImage? {
        let ciContext = CIContext()
        
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else {
            return nil
        }
        
        return cgImage
    }
}
