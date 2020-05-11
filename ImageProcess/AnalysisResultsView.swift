//
//  AnalysisResultsView.swift
//  ImageProcess
//
//  Created by Xiao Yan on 1/9/20.
//  Copyright © 2020 Xiao Yan. All rights reserved.
//

import SwiftUI

struct AnalysisResultsView: View {

    var analysisContext: AnalysisContext = AppContext.shared.analysisContext

    var image: Image = .init("empty")

    @State var isVision: Bool = false

    init() {
        if let uiImage = self.analysisContext.image {
            image = Image(uiImage: uiImage)
        }
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.isVision = false
                    self.analysisContext.isVision = false
                }) {
                    Text("Core Image")
                        .foregroundColor(.white)
                }

                Spacer().frame(width: 100)

                Button(action: {
                    self.isVision = true
                    self.analysisContext.isVision = true
                }) {
                    Text("Vision")
                        .foregroundColor(.white)
                }
            }

            Image(uiImage: analysisContext.imageWithLandmarks!).resizable()
            .background(SwiftUI.Color.white)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.2, alignment: .center)

            if isVision && !analysisContext.faceInfosVision.isEmpty {
                Text("Draw Face Landmarks")
            }
            else if !analysisContext.faceInfosCoreImage.isEmpty {
                Text("Has Smile: \(analysisContext.faceInfosCoreImage[0].hasSmile.description)")
                Text("Left Eye Close: \(analysisContext.faceInfosCoreImage[0].leftEyeClose.description)")
                Text("Right Eye Close: \(analysisContext.faceInfosCoreImage[0].rightEyeClose.description)")
            } else {
                Text("No Face Detected")
            }
            if analysisContext.image?.blurrinessResult() != 100 {
                Text("Clear Lever: \(analysisContext.image!.blurrinessResult())")
            }
        }

    }
}

struct AnalysisResultsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisResultsView()
    }
}
