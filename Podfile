# Uncomment the next line to define a global platform for your project
platform :ios, '17.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'NVR Viewer' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'CocoaMQTT/WebSockets', '2.1.6'
  pod 'MobileVLCKit', '3.6.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end
