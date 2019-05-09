
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


  spec.source_files  = "SGVideoPlayer/SGVideoPlayer/**/*.{h,m}",
			 "SGPlayer/SGPlayer/Classes/**/*.{h,m}"
  spec.exclude_files = "Classes/Exclude"

 s.source_files        = 'SGPlayer/Classes/Extension/SGAVPlayer',
                          'SGPlayer/Classes/Extension/SGAVPlayer/**/*.{h,m}',
                          'SGPlayer/Classes/Core/SGCommon',
                          'SGPlayer/Classes/Support/SGPlatform',
                          'SGPlayer/Classes/Support/SGPlatform/**/*.{h,m}'
  s.public_header_files = 'SGPlayer/Classes/Extension/SGAVPlayer/Classes/SGAVPlayer.h',
                          'SGPlayer/Classes/Core/SGCommon/SGPlayerDefines.h',
                          'SGPlayer/Classes/Core/SGCommon/SGPlayerAction.h',
                          'SGPlayer/Classes/Support/SGPlatform/SGPlatform.h',
                          'SGPlayer/Classes/Support/SGPlatform/**/*.h'
  s.module_map          = 'SGPlayer/Classes/Extension/SGAVPlayer/module.modulemap'





  spec.resources = "SGVideoPlayer/SGVideoPlayer/Slider/ImageResources.bundle"
  spec.requires_arc = true

end
