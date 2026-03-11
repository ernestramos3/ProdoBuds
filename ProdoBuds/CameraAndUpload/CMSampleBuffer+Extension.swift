//
//  CMSampleBuffer+Extension.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/6/26.
//

import AVFoundation
import CoreImage

extension CMSampleBuffer {
    
    var cgImage: CGImage? {
        let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(self)
        
        guard let imagePixelBuffer = pixelBuffer else { return nil }
        
        return CIImage(cvPixelBuffer: imagePixelBuffer).cgImage
    }
}
