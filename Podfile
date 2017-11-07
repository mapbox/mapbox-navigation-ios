# Uncomment the next line to define a global platform for your project
use_frameworks!
platform :ios, '9.0'

def shared_pods
    pod 'Mapbox-iOS-SDK', '~> 3.6'
    pod 'MapboxCoreNavigation', :path => './'
    pod 'MapboxNavigation', :path => './'
end

target 'Example-Objective-C' do
    shared_pods
  target 'Example-Objective-CTests' do
    inherit! :search_paths
    shared_pods
  end
end

target 'Example-Swift' do
    shared_pods
  target 'Example-SwiftTests' do
    inherit! :search_paths
    shared_pods
  end
end

target 'MapboxCoreNavigation' do
    shared_pods
  target 'MapboxCoreNavigationTests' do
    inherit! :search_paths
    shared_pods
  end
end

target 'MapboxNavigation' do
    shared_pods
  target 'MapboxNavigationTests' do
    inherit! :search_paths
    shared_pods
  end
end
