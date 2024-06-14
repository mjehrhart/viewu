//
//  ViewOnBoarding.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/13/24.
//

import SwiftUI

struct ViewOnBoarding: View {
 
    let instructions: [Instructions] = [
        Instructions(title: "Setup Viewu", headline: "Open the Settings view", text: ["\u{2022} Configure Frigate Connection in Settings" ], image: "onboarding_screen1", gradientColors: [Color("ColorBlueberryLight"), Color("ColorBlueberryDark")]),
        
        Instructions(title: "Timeline", headline: "View all events for any camera, zone, or object", text: ["\u{2022} Scroll to view events", "\u{2022} Use the Filter to view specific events", "\u{2022} Click on event card for more details"], image: "onboarding_settings1", gradientColors: [Color("ColorStrawberryLight"), Color("ColorStrawberryDark")]),
        
        Instructions(title: "Live Cameras", headline: "Supports RTSP and HLS", text: ["\u{2022} Select Camera Feed in Settings", "\u{2022} Use Sub Streams when available"], image: "onboarding_home1", gradientColors: [Color("ColorBlueberryLight"), Color("ColorBlueberryDark")]),
        
        Instructions(title: "Notifications", headline: "Receive Notifications for Detected Objects", text: ["\u{2022} Log into MQTT Broker in Settings", "\u{2022} Install Viewu Server using Docker", "\u{2022} Enable Notification Manager in Settings", "\u{2022} Configure Notfication Templates", "\u{2022} Pair Device in Settings"], image: "onboarding_alert1", gradientColors: [Color("ColorStrawberryLight"), Color("ColorStrawberryDark")])
        ]
 

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .gray
        UIPageControl.appearance().pageIndicatorTintColor = .orange
        UIPageControl.appearance().tintColor = .orange
    }
    
    var body: some View {
        
      TabView {
          ForEach(0..<instructions.count) { index in
              ViewInstructions(instruction: instructions[index])
        }
      }
      .foregroundColor(Color.black)
      .tabViewStyle(.page)
      .tableStyle(.inset)
      .tabViewStyle(.page(indexDisplayMode: .always))
      .padding(.vertical, 20)
    }

}

struct OnBoardingView_Previews: PreviewProvider {
    static var previews: some View {
        ViewOnBoarding()
    }
}
