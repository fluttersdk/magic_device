Pod::Spec.new do |s|
  s.name             = 'magic_device'
  s.version          = '0.0.1'
  s.summary          = 'Device signals for Flutter: the macOS window fullscreen channel.'
  s.description      = <<-DESC
Answers the magic_device/window channel for the window that holds the Flutter view.
                       DESC
  s.homepage         = 'https://magic.fluttersdk.com/device'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anılcan Çakır' => 'anilcan.cakir@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'magic_device/Sources/magic_device/**/*'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
