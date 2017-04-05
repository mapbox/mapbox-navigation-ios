Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "MapboxNavigationUI.swift"
  s.version = "0.1.0"
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

  s.source_files = ["MapboxNavigationUI/*", "MapboxNavigation/Geometry.swift"]

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.resources = ['MapboxNavigationUI/Resources/*']

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "MapboxNavigationUI"

  s.dependency "MapboxNavigation.swift"
  s.dependency "MapboxDirections.swift", "~> 0.8"
  s.dependency "Mapbox-iOS-SDK", "~> 3.5"
  s.dependency "OSRMTextInstructions", "~> 0.1"
  s.dependency "Pulley", "~> 1.3"
  s.dependency "SDWebImage", "~> 4.0"
  s.dependency "AWSPolly", "~> 2.5"

  s.xcconfig = {
    "SWIFT_VERSION" => "3.0"
  }

end
