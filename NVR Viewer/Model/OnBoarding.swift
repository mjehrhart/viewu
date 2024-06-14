//
//  OnBoarding.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/13/24.
//

import Foundation
import SwiftUI

struct Instructions: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var headline: String
    var text: [String]?
    var image: String
    var gradientColors: [Color]
}
