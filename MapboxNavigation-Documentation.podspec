Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "MapboxNavigation-Documentation"
  s.version = "0.8.3"
  s.summary = "Complete turn-by-turn navigation interface for iOS."

  s.description  = <<-DESC
  The Mapbox Navigation SDK for iOS is a drop-in interface for turn-by-turn navigation along a route, complete with a well-designed map and easy-to-understand spoken directions. Routes are powered by Mapbox Directions.
                   DESC

  s.homepage = "https://www.mapbox.com/navigation-sdk/"
  s.documentation_url = "https://www.mapbox.com/mapbox-navigation-ios/navigation/"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license = { :type => "ISC", :file => "LICENSE.md" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author = { "Mapbox" => "mobile@mapbox.com" }
  s.social_media_url = "https://twitter.com/mapbox"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source = { :git => "https://github.com/mapbox/mapbox-navigation-ios.git", :tag => "v#{s.version.to_s}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files = ["MapboxNavigation/*", "MapboxCoreNavigation/*"]

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.resources = ['MapboxNavigation/Resources/*/*', 'MapboxNavigation/Resources/*']

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "MapboxNavigation"

  s.dependency "MapboxDirections.swift", "~> 0.10.5"
  s.dependency "Mapbox-iOS-SDK", "~> 3.6"
  s.dependency "OSRMTextInstructions", "~> 0.3"
  s.dependency "Pulley", "1.4"
  s.dependency "SDWebImage", "~> 4.1"
  s.dependency "AWSPolly", "~> 2.6"
  s.dependency "MapboxMobileEvents", "~> 0.2"
  s.dependency "Solar", "~> 2.0"

end
