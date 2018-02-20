Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "MapboxCoreNavigation"
  s.version = "0.13.1"
  s.summary = "Core components for turn-by-turn navigation on iOS."

  s.description  = <<-DESC
  Mapbox Core Navigation provides the core spatial and timing logic for turn-by-turn navigation along a route. For a complete turn-by-turn navigation interface, use the Mapbox Navigation SDK for iOS (MapboxNavigation).
                   DESC

  s.homepage = "https://www.mapbox.com/navigation-sdk/"
  s.documentation_url = "https://www.mapbox.com/mapbox-navigation-ios/navigation/"

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

  s.dependency "MapboxDirections.swift", "~> 0.17"
  s.dependency "MapboxMobileEvents", "~> 0.3"
  s.dependency "Turf", "~> 0.0.4"

  # The CocoaPods podspec spec is not backwards compatible, so, when they add new parameters
  # (like `swift_version` in 1.4.0), older versions of CocoaPods blow up in confusion.
  # Specifying a `cocoapods_version >= 1.4.0` does nothing to solve the problem, as Ruby
  # interprets unknown parameters as low-level syntax errors.
  #
  # Instead, we're forced to use Ruby's built-in semver comparison before declaring parameters
  # added in recent CocoaPods releases.
  if Version.new(Pod::VERSION) >= Version.new("1.4.0")
    s.swift_version = "4.0"
  end

end
