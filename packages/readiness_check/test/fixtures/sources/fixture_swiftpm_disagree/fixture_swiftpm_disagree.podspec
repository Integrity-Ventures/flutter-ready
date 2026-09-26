Pod::Spec.new do |s|
  s.name             = 'fixture_swiftpm_disagree'
  s.version          = '1.0.0'
  s.summary          = 'Synthetic fixture plugin: no Package.swift despite the swiftpm tag.'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m}'
  s.dependency 'Flutter'
  s.ios.deployment_target = '12.0'
end
