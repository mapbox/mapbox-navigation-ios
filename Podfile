platform :ios, '9.0'
use_frameworks!

target 'MapboxNavigation' do
  pod 'MapboxDirections.swift', '~> 0.8'
end

target 'MapboxNavigationUI' do
  pod 'Mapbox-iOS-SDK', '~> 3.4'
  pod 'MapboxDirections.swift', '~> 0.8'
  pod 'MapboxGeocoder.swift', '~> 0.6'
  pod 'SDWebImage', '~> 4.0.0-beta2'
  pod 'OSRMTextInstructions', :git => 'https://github.com/Project-OSRM/osrm-text-instructions.swift.git', :commit => 'bdd962bf5593f951bbbbd26435f732a829dacda7'
  pod 'Pulley', '~> 1.3'
  pod 'AWSPolly', '~> 2.5'
end

target 'Example-Swift' do
  pod 'MapboxNavigation.swift', :path => "."
  pod 'MapboxNavigationUI.swift', :path => "."
end

target 'Example-Objective-C' do
  pod 'MapboxNavigation.swift', :path => "."
  pod 'MapboxNavigationUI.swift', :path => "."
end
