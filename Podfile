platform :ios, '9.0'
use_frameworks!

abstract_target 'Navigation' do
  pod 'MapboxDirections.swift', '~> 0.8'  
  target 'MapboxNavigation' do
  end
  target 'MapboxNavigationTests' do
  end
end

abstract_target 'NavigationUI' do
  pod 'Mapbox-iOS-SDK', '~> 3.4'
  pod 'MapboxDirections.swift', '~> 0.8'
  pod 'MapboxGeocoder.swift', '~> 0.6'
  pod 'SDWebImage', '~> 4.0.0-beta2'
  pod 'OSRMTextInstructions', :git => "https://github.com/Project-OSRM/osrm-text-instructions.swift.git", :branch => "master"
  pod 'Pulley', '~> 1.3'
  target 'MapboxNavigationUI' do
  end
  target 'MapboxNavigationUITests' do
  end
end

def shared_example_pods
  pod 'MapboxNavigation.swift', :path => '.'
  pod 'MapboxNavigationUI.swift', :path => '.'
end

target 'Example-Swift' do
  shared_example_pods
end

target 'Example-Objective-C' do
  shared_example_pods
end
