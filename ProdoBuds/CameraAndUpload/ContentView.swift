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
    @State private var uploadURL: URL? = nil
    
    var body: some View {
        CameraView(viewModel: viewModel)
            // Present a UIKit view controller as a full screen cover when recording is finished
            .fullScreenCover(item: $uploadURL) { url in
                UploadVideoControllerWrapper(videoURL: url)
            }
            // Setup the closure to be called when recording finishes
            .onAppear {
                viewModel.onRecordingFinished = { url in
                    DispatchQueue.main.async {
                        self.uploadURL = url
                    }
                }
            }
    }
    
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    ContentView()
}
