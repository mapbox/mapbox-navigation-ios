platform :ios, '8.0'
use_frameworks!

def shared_pods
    pod 'Mapbox-iOS-SDK', :podspec => 'https://raw.githubusercontent.com/mapbox/mapbox-gl-native/ios-v3.4.0-beta.3/platform/ios/Mapbox-iOS-SDK-symbols.podspec'
    pod 'MapboxDirections.swift', :git => 'https://github.com/mapbox/MapboxDirections.swift.git', :branch => 'fred-objc-compatibility'
end

target 'MapboxNavigation' do
    shared_pods
end

target 'MapboxNavigationTests' do
    shared_pods
end

target 'Example-Swift' do
    shared_pods
end

target 'Example-Objective-C' do
    shared_pods
end
