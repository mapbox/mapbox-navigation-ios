Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "MapboxNavigation-Documentation"
  s.version = "0.20.1"
  s.summary = "Complete turn-by-turn navigation interface for iOS."

  s.description  = <<-DESC
  The Mapbox Navigation SDK for iOS is a drop-in interface for turn-by-turn navigation along a route, complete with a well-designed map and easy-to-understand spoken directions. Routes are powered by Mapbox Directions.
                   DESC

  s.homepage = "https://www.mapbox.com/ios-sdk/navigation/"
  s.documentation_url = "https://www.mapbox.com/mapbox-navigation-ios/navigation/"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license = { :type => "ISC", :file => "LICENSE.md" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author = { "Mapbox" => "mobile@mapbox.com" }
  s.social_media_url = "https://twitter.com/mapbox"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = "12.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source = { :git => "https://github.com/mapbox/mapbox-navigation-ios.git", :tag => "v#{s.version.to_s}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files = ["MapboxNavigation/*", "MapboxCoreNavigation/*"]

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.resources = ['MapboxNavigation/Resources/*/*', 'MapboxNavigation/Resources/*']

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "MapboxNavigation"

  s.frameworks = ['CarPlay']

  s.dependency "MapboxDirections.swift", "~> 0.23.0"
  s.dependency "MapboxGeocoder.swift", "~> 0.10.0"
  s.dependency "Mapbox-iOS-SDK", "~> 4.3"
  s.dependency "MapboxMobileEvents", "~> 0.5"
  s.dependency "Solar", "~> 2.1"
  s.dependency "Turf", "~> 0.2"
  s.dependency "MapboxSpeech", "~> 0.0.1"

  # `swift_version` was introduced in CocoaPods 1.4.0. Without this check, if a user were to
  # directly specify this podspec while using <1.4.0, ruby would throw an unknown method error.
  if s.respond_to?(:swift_version)
    s.swift_version = "4.0"
  end

end
