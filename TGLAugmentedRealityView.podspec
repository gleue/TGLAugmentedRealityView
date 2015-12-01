Pod::Spec.new do |s|
  s.name     = 'TGLAugmentedRealityView'
  s.version  = '1.0.0'
  s.license  = 'MIT'
  s.summary  = 'Place overlays on a camera preview and adjust their position depending on device attitude.'
  s.homepage = 'https://github.com/gleue/TGLAugmentedRealityView'
  s.authors  = { 'Tim Gleue' => 'tim@gleue-interactive.com' }
  s.source   = { :git => 'https://github.com/gleue/TGLAugmentedRealityView.git', :tag => s.version.to_s }
  s.source_files = 'TGLAugmentedRealityView'

  s.requires_arc = true
  s.platform = :ios, '8.0'
end
