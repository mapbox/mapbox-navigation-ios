Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "MapboxCoreNavigation"
  s.version = "0.2.1"
  s.summary = "Core components for turn-by-turn navigation on iOS."

  s.description  = <<-DESC
  Mapbox Core Navigation provides the core spatial and timing logic for turn-by-turn navigation along a route. For a complete turn-by-turn navigation interface, use the Mapbox Navigation SDK for iOS (MapboxNavigation).
                   DESC

  s.homepage = "https://www.mapbox.com/directions/"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license = { :type => "ISC", :file => "LICENSE.md" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author = { "Mapbox" => "mobile@mapbox.com" }
  s.social_media_url = "https://twitter.com/mapbox"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = "8.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source = { :git => "https://github.com/mapbox/mapbox-navigation-ios.git", :tag => "v#{s.version.to_s}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files = "MapboxCoreNavigation"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "MapboxCoreNavigation"

  s.dependency "MapboxDirections.swift", "~> 0.8.0"
  s.dependency "OSRMTextInstructions", "0.1.0"

  s.xcconfig = {
    "SWIFT_VERSION" => "3.0"
  }

end
