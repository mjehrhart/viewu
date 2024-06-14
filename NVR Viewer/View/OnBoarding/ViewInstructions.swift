//
//  ViewOnBoarding.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/13/24.
//

import SwiftUI

struct ViewInstructions: View {
    
    var instruction: Instructions
    
    @State private var isAnimating: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                
                Image(instruction.image)
                    .resizable()
                    .scaledToFit()
                //.shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.15), radius: 8, x: 6, y: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .padding(.top, 0)
                    .frame(alignment: .top)
                
                Text(instruction.title)
                    .foregroundColor(Color.black)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.15), radius: 2, x: 2, y: 2)
                    .frame(alignment: .top)
                    .padding(.top, 0)
                
//                Text(instruction.headline)
//                    .foregroundColor(Color.black)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal, 16)
//                    .frame(maxWidth: 480)
//                    .frame(alignment: .topLeading)
                
                ForEach(0..<instruction.text!.count, id: \.self){ index in
                    Text(instruction.text![index])
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 1)
                        .font(.system(size: 14))
                        .frame(maxWidth: 400 )
                }
                
                StartButtonView()
                    .padding(.vertical, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        .background(LinearGradient(gradient: Gradient(colors: instruction.gradientColors), startPoint: .top, endPoint: .bottom))
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

struct StartButtonView: View {
    
    @AppStorage("isOnboarding") var isOnboarding: Bool? 
    
    var body: some View {
        Button(action: {
            isOnboarding = false
        }) {
            HStack(spacing: 8) {
                Text("Skip")
                
                Image(systemName: "arrow.right.circle")
                    .imageScale(.large)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().strokeBorder(Color.black, lineWidth: 1.25)
            )
        } //: BUTTON
        .accentColor(Color.red)
    }
}

struct StartButtonView_Previews: PreviewProvider {
    static var previews: some View {
        StartButtonView()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}

struct InstructionCardView_Previews: PreviewProvider {
    
    static let instructionsData: [Instructions] = [
        Instructions(title: "Live Cameras", headline: "Supports RTSP and HLS", text: ["1","2","3"], image: "onboarding_alert1", gradientColors: [Color("ColorBlueberryLight"), Color("ColorBlueberryDark")])
    ]
    
    static var previews: some View {
        ViewInstructions(instruction: instructionsData[0])
    }
}



