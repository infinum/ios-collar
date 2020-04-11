#
# Be sure to run `pod lib lint AnalyticsCollector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AnalyticsCollector'
  s.version          = '1.0'
  s.summary          = 'In-app analytics debugging tool.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
In-app analytics debugging tool.
                       DESC

  s.homepage         = 'https://github.com/infinum/ios-analytics-collector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Filip Gulan' => 'gulan.filip@gmail.com' }
  s.source           = { :git => 'https://github.com/infinum/ios-analytics-collector.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'AnalyticsCollector/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AnalyticsCollector' => ['AnalyticsCollector/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit', 'Foundation'
  # s.dependency 'AFNetworking', '~> 2.3'
end
