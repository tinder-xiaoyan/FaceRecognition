//
//  ContentView.swift
//  ImageProcess
//
//  Created by Xiao Yan on 1/8/20.
//  Copyright © 2020 Xiao Yan. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    var analysisContext: AnalysisContext = AppContext.shared.analysisContext

    @State var image: Image = .init("empty")
    @State var showCaptureImageView: Bool = false
    @State var isCameraOn: Bool = false
    @State var hasImage: Bool = false

    var body: some View {
        NavigationView {
        ZStack {
            VStack {
                image.resizable()
                    .background(SwiftUI.Color.gray)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.2, alignment: .center)

                Spacer().frame(height: 20)

                if hasImage {
                    NavigationLink(destination: AnalysisResultsView()) {
                        Text("Start Analysis")
                            .foregroundColor(.white)
                    }
                }

                Spacer().frame(height: 20)

                HStack {
                    Button(action: {
                        self.showCaptureImageView.toggle()
                        self.isCameraOn = true
                    }) {
                        Image(systemName: "camera.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80, alignment: .center)
                            .foregroundColor(.white)
                    }

                    Spacer().frame(width: 100)

                    Button(action: {
                        self.showCaptureImageView.toggle()
                        self.isCameraOn = false
                    }) {
                        Image(systemName: "photo.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80, alignment: .center)
                            .foregroundColor(.white)
                    }
                }

                Spacer().frame(height: 30)
            }
            if (showCaptureImageView) {
                CaptureImageView(isShown: $showCaptureImageView, image: $image, hasImage: $hasImage, isCameraOn: isCameraOn)
            }
        }
        }
        .navigationBarTitle(Text("Navigation!"))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
