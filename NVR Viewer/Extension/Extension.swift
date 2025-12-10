//
//  Extension.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - UIImage

extension UIImage {
    func scale(toWidth newWidth: CGFloat) -> UIImage {
        guard size.width != newWidth else { return self }
        guard size.width > 0 else { return self }

        let scaleFactor = newWidth / size.width
        let newHeight = size.height * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)

        let isOpaque = false  // preserve alpha

        UIGraphicsBeginImageContextWithOptions(newSize, isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: newSize))

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

// MARK: - Rotation helper

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        modifier(DeviceRotationViewModifier(action: action))
    }
}

// MARK: - UIScreen shortcuts

extension UIScreen {
    static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }

    static var screenWidth: CGFloat { screenSize.width }
    static var screenHeight: CGFloat { screenSize.height }
}

// MARK: - Background modifiers

struct SquareBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(0)
            .shadow(color: Color.black.opacity(0.2), radius: 4)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(5)
            .shadow(color: Color.black.opacity(0.2), radius: 4)
    }
}

extension View {
    func squareBackground() -> some View {
        modifier(SquareBackground())
    }

    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}

// MARK: - MQTT trace logging

extension MQTTManager {
    func trace(_ message: String = "", function: String = #function) {
        let components = function.components(separatedBy: ":")
        var prettyName = components.last ?? function

        if function == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}

// MARK: - Optional logging helper

//extension Optional {
//    // Unwrap optional value for printing log only
//    var description: String {
//        if let wraped = self {
//            return "\(wraped)"
//        }
//        return ""
//    }
//}

extension Optional {
    /// For logging: prints wrapped value, or "" for nil.
    var logDescription: String {
        switch self {
        case .some(let wrapped):
            return String(describing: wrapped)
        case .none:
            return ""
        }
    }
}

// MARK: - Array RawRepresentable via JSON

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else { return nil }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}


// MARK: - Remove
////  Extension.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/1/24.
////
// 
//import Foundation
//import SwiftUI
//import UIKit
//
//extension UIImage
//{
//    func scale(newWidth: CGFloat) -> UIImage
//    {
//        guard self.size.width != newWidth else{return self}
//        
//        let scaleFactor = newWidth / self.size.width
//        
//        let newHeight = self.size.height * scaleFactor
//        let newSize = CGSize(width: newWidth, height: newHeight)
//        
//        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
//        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
//        
//        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
//        return newImage ?? self
//    }
//}
//
//extension View {
//    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
//        modifier(DeviceRotationViewModifier(action: action))
//    }
//}
//
//extension UIScreen {
//    static var screenWidth: CGFloat {
//        UIScreen.main.bounds.width
//    }
//    
//    static var screenHeight: CGFloat {
//        UIScreen.main.bounds.height
//    }
//}
//
//struct SquareBackground: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .cornerRadius(0)
//            .shadow(color: Color.black.opacity(0.2), radius: 4)
//    }
//}
//
//struct CardBackground: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .cornerRadius(5)
//            .shadow(color: Color.black.opacity(0.2), radius: 4)
//    }
//}
//  
//extension View {
//    func cardBackground() -> some View {
//        modifier(CardBackground())
//    }
//}
//
//extension MQTTManager {
//    func TRACE(_ message: String = "", fun: String = #function) {
//        let names = fun.components(separatedBy: ":")
//        var prettyName: String
//        if names.count == 1 {
//            prettyName = names[0]
//        } else {
//            prettyName = names[1]
//        }
//
//        if fun == "mqttDidDisconnect(_:withError:)" {
//            prettyName = "didDisconect"
//        }
//
//        print("[TRACE] [\(prettyName)]: \(message)")
//    }
//}
//
//extension Optional {
//    // Unwrap optional value for printing log only
//    var description: String {
//        if let wraped = self {
//            return "\(wraped)"
//        }
//        return ""
//    }
//}
//
//extension Array: @retroactive RawRepresentable where Element: Codable {
//    public init?(rawValue: String) {
//        guard let data = rawValue.data(using: .utf8),
//              let result = try? JSONDecoder().decode([Element].self, from: data)
//        else { return nil }
//        self = result
//    }
//
//    public var rawValue: String {
//        guard let data = try? JSONEncoder().encode(self),
//              let result = String(data: data, encoding: .utf8)
//        else {
//            return "[]"
//        }
//        return result
//    }
//}
