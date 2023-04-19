#
# Be sure to run `pod lib lint DyteUiKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DyteUiKit'
  s.version          = '0.1.1'
  s.summary          = 'Customise UI of your Dyte meetings'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "Customise UI of your Dyte meetings. You can use this prebuilt meeting flow or you can customise it on individual component level"

  s.homepage         = 'https://dyte.io/'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.author           = { 'Dyte' => 'dev@dyte.io' }
  s.source           = { :git => 'https://github.com/dyte-in/ios-uikit-framework.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.ios.deployment_target = '12.0'

  s.vendored_frameworks = "DyteUiKit.framework"
 s.platform = :ios
 s.swift_version = "5.0"
 s.ios.deployment_target  = '12.0'
 s.dependency 'DyteiOSCore'


end
