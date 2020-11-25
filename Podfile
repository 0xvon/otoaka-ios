install! 'cocoapods', integrate_targets: false
platform :ios, '13.0'
source 'https://cdn.cocoapods.org/'

target 'Rocket' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Rocket
  pod 'AWSCognitoAuth'
  pod 'AWSS3'
  pod 'KeychainAccess'

  target 'RocketTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'RocketUITests' do
    # Pods for testing
  end

end
