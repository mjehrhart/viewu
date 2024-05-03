//
//  ViewUIImageByData.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/4/24.
//

import SwiftUI

struct ViewUIImageByData: View {
     
    let data: Data?
    @State private var zoomIn: Bool = false
    
    var body: some View {
        
        if data != nil {
            let tmpImage:UIImage = UIImage(data: data!) ?? UIImage()
            Image(uiImage: tmpImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: self.zoomIn ? UIScreen.screenWidth-15: 250, height:self.zoomIn ? UIScreen.screenWidth : 150 ) 
                .transition(.slide)
                .onAppear{
                    
                }
                .onTapGesture{
                    withAnimation {
                        zoomIn.toggle()
                    }
                }
        }
    }
}

extension UIImage {
    func aspectFittedToHeight(_ newHeight: CGFloat) -> UIImage {
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
