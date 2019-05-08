#
#  Be sure to run `pod spec lint SGVideoPlayer.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "SGVideoPlayer"
  spec.version      = "1.0.0"
  spec.summary      = "SGVideoPlayer can play normal video and VR video"
  spec.description  = "SGVideoPlayer based on SGPlayer whitch can play normal video and VR video"

  spec.homepage     = "https://github.com/yegail/SGPlayer-iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE.md" }

  spec.author             = { "yegail" => "642182927@qq.com" }
  spec.platform     = :ios, "9.0"

  spec.source       = { :git => "https://github.com/yegail/SGPlayer-iOS.git", :tag => "#{spec.version}" }


  spec.source_files  = "SGVideoPlayer/SGVideoPlayer/**/*.{h,m}", "SGPlayer/SGPlayer/Classes/**/*.{h,m}"
  spec.exclude_files = "Classes/Exclude"

  spec.resources = "SGVideoPlayer/SGVideoPlayer/Slider/ImageResources.bundle"
  spec.requires_arc = true

  spec.dependency "SGPlayer/SGPlatform/*"

end
