//
//  ViewTips.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 11/16/25.
//

import SwiftUI
 
struct ViewTipsNotificationManager: View {
  
    //@State var showTip: Bool = true
    @AppStorage("tipsNotificationDefault") private var tipsNotificationDefault: Bool = true
    
    let title: String
    let message: String
    
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)
    
    init(title: String, message: String ) {
        self.title = title
        self.message = message
    }
    
    var  body: some View {
        
        if tipsNotificationDefault {
            HStack{
                
                ZStack(alignment: .topTrailing) {
                    
                    Image(systemName: "info.bubble")
                        .resizable()
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .frame(alignment: .top)
                        .padding(.top, 10)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Color.clear
                        .frame(maxWidth: 40, maxHeight: .infinity)
                }
                .padding(.leading, 10)
 
                VStack(alignment: .leading){
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 17, weight: .semibold))
                        .textCase(nil)
                        .padding(.bottom, 1)
                    
                    Text(message)
                        .foregroundStyle(.gray)
                        //.font(.system(size: 15.2))
                        .textCase(nil)
                        .font(.system(size: 13.2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                //.padding(.leading, 7)
                .padding(.bottom, 7)
                .frame(maxWidth: .infinity)
                
                VStack{
                    Image(systemName: "xmark")
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                        .foregroundStyle(.gray)
                        //.foregroundStyle(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(alignment: .top)
                        .onTapGesture {
                            tipsNotificationDefault.toggle()
                        }
                    Spacer()
                }
            }
            .padding(10)
            //.background(Color(.systemGray6))
            .background(Color(.white))
            .cornerRadius(15)
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
            .frame(width: UIScreen.screenWidth - 30 )
            //.background(Color.white)
        }
        else {
            
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .padding(.top, 10)
                    .foregroundStyle(.gray)
                    .font(.system(size: 18, weight: .bold))
                    .onTapGesture {
                        tipsNotificationDefault.toggle()
                    }
            }
        }
    }
}
 
struct ViewTipsNotificationDomain: View {
  
    //@State var showTip: Bool = true
    @AppStorage("tipsNotificationDomain") private var tipsNotificationDomain: Bool = true
    
    let title: String
    let message: String
    
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)
    
    init(title: String, message: String ) {
        self.title = title
        self.message = message
    }
    
    var  body: some View {
        
        if tipsNotificationDomain {
            HStack{
                
                ZStack(alignment: .topTrailing) {
                    
                    Image(systemName: "info.bubble")
                        .resizable()
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .frame(alignment: .top)
                        .padding(.top, 10)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Color.clear
                        .frame(maxWidth: 40, maxHeight: .infinity)
                }
                .padding(.leading, 10)
 
                VStack(alignment: .leading){
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 17, weight: .semibold))
                        .textCase(nil)
                        .padding(.bottom, 1)
                    
                    Text(message)
                        .foregroundStyle(.gray)
                        //.font(.system(size: 15.2))
                        .textCase(nil)
                        .font(.system(size: 13.2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                //.padding(.leading, 7)
                .padding(.bottom, 7)
                .frame(maxWidth: .infinity)
                
                VStack{
                    Image(systemName: "xmark")
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                        .foregroundStyle(.gray)
                        //.foregroundStyle(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(alignment: .top)
                        .onTapGesture {
                            tipsNotificationDomain.toggle()
                        }
                    Spacer()
                }
            }
            .padding(10)
            //.background(Color(.systemGray6))
            .background(Color(.white))
            .cornerRadius(15)
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
            .frame(width: UIScreen.screenWidth - 30 )
            //.background(Color.white)
        }
        else {
            
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .padding(.top, 10)
                    .foregroundStyle(.gray)
                    .font(.system(size: 18, weight: .bold))
                    .onTapGesture {
                        tipsNotificationDomain.toggle()
                    }
            }
        }
    }
}

struct ViewTipsNotificationTemplate: View {
  
    //@State var showTip: Bool = true
    @AppStorage("tipsNotificationTemplate") private var tipsNotificationTemplate: Bool = true
    
    let title: String
    let message: String
    
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)
    
    init(title: String, message: String ) {
        self.title = title
        self.message = message
    }
    
    var  body: some View {
        
        if tipsNotificationTemplate {
            HStack{
                
                ZStack(alignment: .topTrailing) {
                    
                    Image(systemName: "info.bubble")
                        .resizable()
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .frame(alignment: .top)
                        .padding(.top, 10)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Color.clear
                        .frame(maxWidth: 40, maxHeight: .infinity)
                }
                .padding(.leading, 10)
 
                VStack(alignment: .leading){
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 17, weight: .semibold))
                        .textCase(nil)
                        .padding(.bottom, 1)
                    
                    Text(message)
                        .foregroundStyle(.gray)
                        //.font(.system(size: 15.2))
                        .textCase(nil)
                        .font(.system(size: 13.2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                //.padding(.leading, 7)
                .padding(.bottom, 7)
                .frame(maxWidth: .infinity)
                
                VStack{
                    Image(systemName: "xmark")
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                        .foregroundStyle(.gray)
                        //.foregroundStyle(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(alignment: .top)
                        .onTapGesture {
                            tipsNotificationTemplate.toggle()
                        }
                    Spacer()
                }
            }
            .padding(10)
            //.background(Color(.systemGray6))
            .background(Color(.white))
            .cornerRadius(15)
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
            .frame(width: UIScreen.screenWidth - 30 )
            //.background(Color.white)
        }
        else {
            
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .padding(.top, 10)
                    .foregroundStyle(.gray)
                    .font(.system(size: 18, weight: .bold))
                    .onTapGesture {
                        tipsNotificationTemplate.toggle()
                    }
            }
        }
    }
}

struct ViewTipsSettingsNVR: View {
  
    //@State var showTip: Bool = true
    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true
    
    let title: String
    let message: String
    
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)
    
    init(title: String, message: String ) {
        self.title = title
        self.message = message
    }
    
    var  body: some View {
        
        if tipsSettingsNVR {
            HStack{
                
                ZStack(alignment: .topTrailing) {
                    
                    Image(systemName: "info.bubble")
                        .resizable()
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .frame(alignment: .top)
                        .padding(.top, 10)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Color.clear
                        .frame(maxWidth: 40, maxHeight: .infinity)
                }
                .padding(.leading, 10)
 
                VStack(alignment: .leading){
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 17, weight: .semibold))
                        .textCase(nil)
                        .padding(.bottom, 1)
                    
                    Text(message)
                        .foregroundStyle(.gray)
                        //.font(.system(size: 15.2))
                        .textCase(nil)
                        .font(.system(size: 13.2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                //.padding(.leading, 7)
                .padding(.bottom, 7)
                .frame(maxWidth: .infinity)
                
                VStack{
                    Image(systemName: "xmark")
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                        .foregroundStyle(.gray)
                        //.foregroundStyle(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(alignment: .top)
                        .onTapGesture {
                            tipsSettingsNVR.toggle()
                        }
                    Spacer()
                }
            }
            .padding(10)
            //.background(Color(.systemGray6))
            .background(Color(.white))
            .cornerRadius(15)
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
            .frame(width: UIScreen.screenWidth - 30 )
            //.background(Color.white)
        }
        else {
            
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .padding(.top, 10)
                    .foregroundStyle(.gray)
                    .font(.system(size: 18, weight: .bold))
                    .onTapGesture {
                        tipsSettingsNVR.toggle()
                    }
            }
        }
    }
}

struct ViewTipsSettingsPairDevie: View {
  
    //@State var showTip: Bool = true
    @AppStorage("tipsSettingsPairDevice") private var tipsSettingsPairDevice: Bool = true
    
    let title: String
    let message: String
    
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)
    
    init(title: String, message: String ) {
        self.title = title
        self.message = message
    }
    
    var  body: some View {
        
        if tipsSettingsPairDevice {
            HStack{
                
                ZStack(alignment: .topTrailing) {
                    
                    Image(systemName: "info.bubble")
                        .resizable()
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .frame(alignment: .top)
                        .padding(.top, 10)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Color.clear
                        .frame(maxWidth: 40, maxHeight: .infinity)
                }
                .padding(.leading, 10)
 
                VStack(alignment: .leading){
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 17, weight: .semibold))
                        .textCase(nil)
                        .padding(.bottom, 1)
                    
                    Text(message)
                        .foregroundStyle(.gray)
                        //.font(.system(size: 15.2))
                        .textCase(nil)
                        .font(.system(size: 13.2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                //.padding(.leading, 7)
                .padding(.bottom, 7)
                .frame(maxWidth: .infinity)
                
                VStack{
                    Image(systemName: "xmark")
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                        .foregroundStyle(.gray)
                        //.foregroundStyle(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(alignment: .top)
                        .onTapGesture {
                            tipsSettingsPairDevice.toggle()
                        }
                    Spacer()
                }
            }
            .padding(10)
            //.background(Color(.systemGray6))
            .background(Color(.white))
            .cornerRadius(15)
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
            .frame(width: UIScreen.screenWidth - 30 )
            //.background(Color.white)
        }
        else {
            
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .padding(.top, 10)
                    .foregroundStyle(.gray)
                    .font(.system(size: 18, weight: .bold))
                    .onTapGesture {
                        tipsSettingsPairDevice.toggle()
                    }
            }
        }
    }
}

struct ViewTipsLiveCameras: View {
  
    //@State var showTip: Bool = true
    @AppStorage("tipsLiveCameras") private var tipsLiveCameras: Bool = true
    
    let title: String
    let message: String
    
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)
    
    init(title: String, message: String ) {
        self.title = title
        self.message = message
    }
    
    var  body: some View {
        
        if tipsLiveCameras {
            HStack{
                
                ZStack(alignment: .topTrailing) {
                    
                    Image(systemName: "info.bubble")
                        .resizable()
                        //.foregroundColor(iconColor)
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .frame(alignment: .top)
                        .padding(.top, 10)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Color.clear
                        .frame(maxWidth: 40, maxHeight: .infinity)
                }
                .padding(.leading, 10)
 
                VStack(alignment: .leading){
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.bottom, 1)
                    
                    Text(message)
                        .foregroundStyle(.gray)
                        .font(.system(size: 15.2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding(.leading, 7)
                .padding(.bottom, 7)
                .frame(maxWidth: .infinity)
                
                VStack{
                    Image(systemName: "xmark")
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                        .foregroundStyle(.gray)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(alignment: .top)
                        .onTapGesture {
                            tipsLiveCameras.toggle()
                        }
                    Spacer()
                }
            }
            .padding(.top, 5)
            .padding(.leading, 3)
            .padding(.trailing, 3)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .frame( maxHeight: .infinity)
        }
        else {
            
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 15, height: 15)
                    //.padding(.top, 10)
                    .foregroundStyle(.gray)
                    .font(.system(size: 18, weight: .bold))
                    .onTapGesture {
                        tipsLiveCameras.toggle()
                    }
            }
        }
    }
}
