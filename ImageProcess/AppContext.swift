//
//  AppContext.swift
//  ImageProcess
//
//  Created by Xiao Yan on 1/9/20.
//  Copyright © 2020 Xiao Yan. All rights reserved.
//

import Foundation

final class AppContext {
    static let shared: AppContext = .init()
    lazy var analysisContext: AnalysisContext = .init()
}
