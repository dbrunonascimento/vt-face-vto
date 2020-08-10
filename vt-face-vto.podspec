require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "vt-face-vto"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  VT Face VTO Module
                   DESC
  s.homepage     = "https://github.com/syahman-vettons/vt-face-vto"
  s.license      = "MIT"
  s.swift_version= '4.2'
  # s.license    = { :type => "MIT", :file => "FILE_LICENSE" }
  s.authors      = { "Muhammad Syahman" => "syahman@vettons.com" }
  s.platforms    = { :ios => "9.0" }
  s.source       = { :git => "https://github.com/syahman-vettons/vt-face-vto.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,swift}"
  s.requires_arc = true

  s.dependency "React"
  s.dependency 'ARCore/AugmentedFaces', '~> 1.18.0'
  s.dependency 'CircularCarousel'
  s.dependency 'SDWebImageWebPCoder'
  # ...
  # s.dependency "..."

  s.resource_bundles = {
    'VTOAsset' => ['ios/vtFaceVTO/Assets.xcassets'],
    'VTOFaceAsset' => ['ios/vtFaceVTO/Face.scnassets']
  }
end

