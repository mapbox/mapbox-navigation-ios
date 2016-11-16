platform :ios, '8.0'
use_frameworks!

def shared_pods
    pod 'Mapbox-iOS-SDK', :podspec => 'https://raw.githubusercontent.com/mapbox/mapbox-gl-native/ios-v3.4.0-beta.3/platform/ios/Mapbox-iOS-SDK-symbols.podspec'
    pod 'MapboxDirections.swift', :git => 'https://github.com/mapbox/MapboxDirections.swift.git', :commit => '117f155dcf6295e01be9f927399b7deedf983294'
end

target 'MapboxNavigation' do
    shared_pods
end

target 'MapboxNavigationTests' do
    shared_pods
end

target 'Example' do
    shared_pods
end
