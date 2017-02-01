Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "MapboxNavigationUI.swift"
  s.version = "0.0.1"
  s.summary = "Mapbox Navigation UI library"

  s.description  = <<-DESC
  MapboxNavigationUI.swift makes it easy to get step by step UI for guiding a user along a route.
                   DESC

  s.homepage = "https://www.mapbox.com/directions/"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license = { :type => "ISC", :file => "LICENSE.md" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author = { "Mapbox" => "mobile@mapbox.com" }
  s.social_media_url = "https://twitter.com/mapbox"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source = { :git => "https://github.com/mapbox/MapboxNavigation.swift.git", :tag => "v#{s.version.to_s}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files = "MapboxNavigationUI"

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.resource_bundle = { "MapboxNavigationUI" => 'Resources/*.storyboard' }

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "MapboxNavigationUI"

  s.dependency "MapboxNavigation.swift"
  s.dependency "MapboxDirections.swift"
  s.dependency "Mapbox-iOS-SDK"
  s.dependency "Pulley"
  s.dependency "SDWebImage"

  s.xcconfig = {
    "SWIFT_VERSION" => "3.0"
  }

end
