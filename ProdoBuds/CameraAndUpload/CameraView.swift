//
//  CameraView.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/7/26.
//

import SwiftUI

struct CameraView: View {
    
    @Bindable var viewModel: ViewModel
    @State private var showFPSSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    if let image = viewModel.currentFrame {
                        let imageSize = CGSize(width: CGFloat(image.width), height: CGFloat(image.height))
                        let containerSize = CGSize(width: geometry.size.width, height: geometry.size.height * 0.9)
                        
                        // After rotation, width and height are swapped
                        let rotatedImageSize = CGSize(width: imageSize.height, height: imageSize.width)
                        
                        // Calculate scale factors
                        let scaleX = containerSize.width / rotatedImageSize.width
                        
                        let scale = scaleX
                        
                        Image(decorative: image, scale: 1)
                            .resizable()
                            .rotationEffect(.degrees(90))
                            .frame(width: imageSize.width * scale, height: imageSize.height * scale)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.9)
                            .clipped()
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(.gray.opacity(0.3))
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.9)
                    }
                    
                    // Overlay with time and FPS
                    VStack {
                        HStack {
                            // Elapsed Time - Top Left
                            Text(viewModel.elapsedTime)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                .padding()
                            
                            Spacer()
                            
                            // Settings Icon - Top Center
                            Button(action: {
                                showFPSSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            }
                            
                            Spacer()
                            
                            // FPS - Top Right
                            Text("\(String(format: "%.1f", viewModel.fps)) FPS")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                .padding()
                        }
                        
                        Spacer()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.9)
                
                Spacer()
                // Bottom button area
                HStack {
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleRecording()
                    }) {
                        ZStack {
                            // Outer ring
                            Circle()
                                .strokeBorder(viewModel.isRecording ? Color.red : Color.green, lineWidth: 3)
                                .frame(width: 70, height: 70)
                            
                            // Inner circle - becomes a rounded square when recording
                            if viewModel.isRecording {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .frame(width: 40, height: 40)
                            } else {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 58, height: 58)
                            }
                        }
                    }
                    
                    Spacer()
                    
                }
                .frame(height: geometry.size.height * 0.1)
            }
        }
        .confirmationDialog("Select Capture FPS", isPresented: $showFPSSettings, titleVisibility: .visible) {
            Button("2 FPS (15x speed)") {
                viewModel.setCaptureFPS(2)
            }
            
            Button("5 FPS (6x speed)") {
                viewModel.setCaptureFPS(5)
            }
            
            Button("10 FPS (3x speed)") {
                viewModel.setCaptureFPS(10)
            }
            
            Button("15 FPS (2x speed)") {
                viewModel.setCaptureFPS(15)
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how many frames per second to capture. Lower FPS creates faster timelapse playback at 30 FPS.")
        }
    }
}

#Preview {
    CameraView(viewModel: ViewModel())
}
