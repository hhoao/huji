Pod::Spec.new do |s|
  s.name             = 'native_splash_screen_macos'
  s.version          = '3.0.0'
  s.summary          = 'MacOS implementation of the native_splash_screen plugin.'
  s.description      = <<-DESC
MacOS implementation of the native_splash_screen plugin.
                       DESC
  s.homepage         = 'https://github.com/anicine/native_splash_screen'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anicine Project' => 'yacine2700dj@gmail.com' }

  s.source           = { :path => '.' }
  
  s.source_files = 'Classes/**/*.swift'
  s.resources = 'Resources/**/*'
  
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
end