install! 'cocoapods', integrate_targets: false
platform :ios, '13.0'
source 'https://cdn.cocoapods.org/'

target 'Rocket' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for Rocket
  pod 'AWSCognitoAuth', '~> 2.21.1'
  pod 'AWSS3'
  pod 'KeychainAccess'
  pod 'LicensePlist'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics', '7.3-M1'
  pod 'SwiftGen', '~> 6.0'
  pod 'KeyboardGuide', :podspec => './KeyboardGuide.podspec'
  pod 'Nuke', '~> 9.0'
  pod 'UITextView+Placeholder'
  pod "YoutubePlayer-in-WKWebView", "~> 0.3.0" 

  target 'RocketTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'RocketUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
