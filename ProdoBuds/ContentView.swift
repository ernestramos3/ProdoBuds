//
//  ContentView.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/7/26.
//

import SwiftUI

struct ContentView: View {
    
    // State object holding the camera view model
    @State private var viewModel = ViewModel()
    
    // State to control showing the upload view controller
    @State private var showUploadVC = false
    
    // URL of the video to upload
    @State private var uploadURL: URL? = nil
    
    // String representing elapsed time of the recording
    @State private var uploadElapsed: String? = nil
    
    var body: some View {
        CameraView(viewModel: viewModel)
            // Present a UIKit view controller as a full screen cover when recording is finished
            .fullScreenCover(isPresented: $showUploadVC) {
                // Only present UploadVideoControllerWrapper if both video URL and elapsed time are set
                
                if let videoURL = uploadURL, let timeElapsed = uploadElapsed {
                    UploadVideoControllerWrapper(videoURL: videoURL, timeElapsed: timeElapsed)
                } else {
                    UploadVideoControllerWrapper(videoURL: nil, timeElapsed: nil)
                }
            }
            // Setup the closure to be called when recording finishes
            .onAppear {
                // Assign the closure to viewModel's onRecordingFinished property
                viewModel.onRecordingFinished = { url, elapsed in
                    // Update state properties on the main thread
                    DispatchQueue.main.async {
                        print("Updating url and elapsed")
                        print("url: \(url)")
                        print("elapsed: \(elapsed)")
                        self.uploadURL = url
                        self.uploadElapsed = elapsed
                        self.showUploadVC = true
                    }
                }
            }
    }
    
}

#Preview {
    ContentView()
}
