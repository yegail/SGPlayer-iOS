
Pod::Spec.new do |spec|

  spec.name         = "SGPlayer-iOS"
  spec.version      = "1.0.1"
  spec.summary      = "SGPlayer-iOS can play normal video and VR video"
  spec.description  = "SGPlayer-iOS based on SGPlayer whitch can play normal video and VR video"

  spec.homepage     = "https://github.com/yegail/SGPlayer-iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE.md" }

  spec.author       = { "yegail" => "642182927@qq.com" }
  spec.platform     = :ios, "9.0"

  spec.source       = { :git => "https://github.com/yegail/SGPlayer-iOS.git", :tag => "#{spec.version}" }


  #spec.exclude_files = "Classes/Exclude"

  spec.source_files  = ["SGPlayer/SGPlayer/Classes", "SGPlayer/SGPlayer/Classes/**/*.{h,m}"]

  #spec.module_map   = 'SGPlayer/Classes/Extension/SGAVPlayer/module.modulemap'
  
  spec.frameworks    = 'AudioToolbox', 'VideoToolBox', 'CoreMedia'





  #spec.resources = "SGVideoPlayer/SGVideoPlayer/Slider/ImageResources.bundle"
  spec.requires_arc = true

end
