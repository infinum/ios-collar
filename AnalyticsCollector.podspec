Pod::Spec.new do |s|
  s.name             = 'AnalyticsCollector'
  s.version          = '1.0'
  s.summary          = 'In-app analytics debugging tool.'
  s.description      = <<-DESC
In-app analytics debugging tool.
                       DESC

  s.homepage         = 'https://github.com/infinum/ios-analytics-collector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Filip Gulan' => 'gulan.filip@gmail.com' }
  s.source           = { :git => 'https://github.com/infinum/ios-analytics-collector.git', :tag => s.version.to_s }
  s.platform         = :ios
  s.swift_version    = '5.1'
  s.ios.deployment_target = '10.0'
  s.source_files = 'AnalyticsCollector/Classes/**/*'
  s.resource_bundles = { 'AnalyticsCollector' => ['AnalyticsCollector/Assets/**/*'] }
  s.frameworks = 'UIKit'
end
