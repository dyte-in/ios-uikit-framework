#
# Be sure to run `pod lib lint DyteUiKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DyteUiKit'
  s.version          = '0.2.0'
  s.summary          = 'Customise UI of your Dyte meetings'

  s.description      = "Customise UI of your Dyte meetings. You can use this prebuilt meeting flow or you can customise it on individual component level"

  s.homepage         = 'https://dyte.io/'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.author           = { 'Dyte' => 'dev@dyte.io' }
  s.source           = { :git => 'https://github.com/dyte-in/ios-uikit-framework.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.ios.deployment_target  = '13.0'
  s.vendored_frameworks = "DyteUiKit.framework"
  s.platform = :ios, '13.0'
  s.swift_version = "5.0"
  s.dependency 'DyteiOSCore' , '~> 0.4.2'
end
