//
//  ContentView.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/7/26.
//

import SwiftUI

struct ContentView: View {
    
    @State private var viewModel = ViewModel()
    
    var body: some View {
        CameraView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
