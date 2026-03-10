//
//  ViewModel.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/7/26.
//

import Foundation
import CoreImage
import Observation
import Photos

@Observable
class ViewModel {
    var currentFrame: CGImage?
    var isRecording = false
    var elapsedTime: String = "00:00"
    var fps: Double = 0.0
    var lastSavedVideoURL: URL?
    
    private let cameraManager = CameraManager()
    private var recordingStartTime: Date?
    private var timerTask: Task<Void, Never>?
    
    init() {
        Task {
            await handleCameraPreviews()
        }
    }
    
    func handleCameraPreviews() async {
        for await image in cameraManager.previewStream {
            Task { @MainActor in
                currentFrame = image
            }
        }
    }
    
    @MainActor
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        recordingStartTime = Date()
        
        // Start actual video recording
        cameraManager.startRecording()
        
        // Start the timer
        timerTask = Task {
            while !Task.isCancelled {
                if let startTime = recordingStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    await updateElapsedTime(elapsed)
                }
                
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        
        print("Recording started")
    }
    
    @MainActor
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        timerTask?.cancel()
        timerTask = nil
        
        // Stop actual video recording
        cameraManager.stopRecording { [weak self] url in
            guard let self = self else { return }
            
            if let url = url {
                Task { @MainActor in
                    self.lastSavedVideoURL = url
                    print("Video saved to: \(url.path)")
                    
                    // Optionally save to Photos library
                    await self.saveToPhotosLibrary(url: url)
                }
            } else {
                print("Failed to save video")
            }
        }
        
        // Reset timer
        elapsedTime = "00:00"
        recordingStartTime = nil
        
        print("Recording stopped")
    }
    
    @MainActor
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @MainActor
    private func updateElapsedTime(_ timeInterval: TimeInterval) {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        elapsedTime = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Photo Library
    
    private func saveToPhotosLibrary(url: URL) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        var authorized = status == .authorized
        
        if status == .notDetermined {
            authorized = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        }
        
        guard authorized else {
            print("Photo library access denied")
            return
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            print("Video saved to Photos library successfully")
        } catch {
            print("Failed to save video to Photos library: \(error.localizedDescription)")
        }
    }
}
