platform :ios, '8.0'
use_frameworks!

def shared_pods
    pod 'Mapbox-iOS-SDK-symbols', :podspec => 'https://raw.githubusercontent.com/mapbox/mapbox-gl-native/ios-v3.4.0-rc.1/platform/ios/Mapbox-iOS-SDK-symbols.podspec'
    pod 'MapboxDirections.swift', :git => 'https://github.com/mapbox/MapboxDirections.swift.git', :commit => 'ceaf58b780fc17ea44a9150041b602d017c1e567'
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
