//
//  CaptureImageView.swift
//  ImageProcess
//
//  Created by Xiao Yan on 1/8/20.
//  Copyright © 2020 Xiao Yan. All rights reserved.
//

import Foundation
import SwiftUI

struct CaptureImageView {
    @Binding var isShown: Bool
    @Binding var image: Image
    @Binding var hasImage: Bool

    var isCameraOn: Bool

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown, image: $image, hasImage: $hasImage)
    }
}

extension CaptureImageView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureImageView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if isCameraOn {
            picker.sourceType = .camera
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<CaptureImageView>) {

    }
}
