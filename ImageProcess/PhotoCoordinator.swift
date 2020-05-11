//
//  PhotoCoordinator.swift
//  ImageProcess
//
//  Created by Xiao Yan on 1/9/20.
//  Copyright © 2020 Xiao Yan. All rights reserved.
//

import Foundation
import SwiftUI

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @Binding var isCoordinatorShown: Bool
    @Binding var imageInCoordinator: Image
    @Binding var hasImage: Bool

    var analysisContext: AnalysisContext = AppContext.shared.analysisContext
    
    init(isShown: Binding<Bool>, image: Binding<Image>, hasImage: Binding<Bool>) {
        _isCoordinatorShown = isShown
        _imageInCoordinator = image
        _hasImage = hasImage
    }
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let unwrapImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        analysisContext.image = unwrapImage
        imageInCoordinator = Image(uiImage: unwrapImage)
        isCoordinatorShown = false
        hasImage = true
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isCoordinatorShown = false
    }
}
