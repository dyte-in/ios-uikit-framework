#
# Be sure to run `pod lib lint DyteUiKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DyteUiKit'
  s.version          = '0.4.8'
  s.summary          = 'Customise UI of your Dyte meetings'

  s.description      = "Customise UI of your Dyte meetings. You can use this prebuilt meeting flow or you can customise it on individual component level"

  s.homepage         = 'https://dyte.io/'
  s.author           = { 'Dyte' => 'dev@dyte.io' }
  s.source           = { :git => 'https://github.com/dyte-in/ios-uikit-framework.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dyte_io'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.ios.deployment_target  = '13.0'
  s.source_files = 'DyteUiKit/DyteUiKit/**/**'
  s.platform = :ios, '13.0'
  s.swift_version = "5.0"
  s.ios.frameworks = ['UIKit', 'AVFAudio']
  s.resource_bundle = { 'DyteUiKit' => 'DyteUiKit/Resources/*' }
  s.dependency 'DyteiOSCore' , '~> 1.29.0'
  s.dependency 'AmazonIVSPlayer' , '~> 1.19.0'
  s.module_name = 'DyteUiKit'

end
