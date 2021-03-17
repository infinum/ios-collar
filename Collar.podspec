Pod::Spec.new do |s|
  s.name                  = 'Collar'
  s.version               = '1.0'
  s.summary               = 'In-app analytics debugging tool'
  s.description           = <<-DESC
                          Collar simplifies analytics debugging by showing events, screen views and user properties of your app as they happen.
                          DESC
  s.homepage              = 'https://github.com/infinum/ios-collar'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'Filip Gulan' => 'gulan.filip@gmail.com' }
  s.source                = { :git => 'https://github.com/infinum/ios-collar.git', :tag => s.version.to_s }
  s.platform              = :ios
  s.swift_version         = "5.1"
  s.ios.deployment_target = '11.0'
  s.source_files          = 'Sources/Collar/Classes/**/*'
  s.resource_bundles      = { 'Collar' => ['Sources/Collar/Assets/**/*'] }
  s.frameworks            = 'UIKit'
end
