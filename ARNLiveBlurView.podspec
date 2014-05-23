Pod::Spec.new do |s|
  s.name         = "ARNLiveBlurView"
  s.version      = "0.1.0"
  s.summary      = "Blur Effect And observe ScrollView contentOffset."
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage     = "https://github.com/xxxAIRINxxx/ARNLiveBlurView"
  s.author       = { "Airin" => "xl1138@gmail.com" }
  s.source       = { :git => "https://github.com/xxxAIRINxxx/ARNLiveBlurView.git", :tag => "#{s.version}" }
  s.platform     = :ios, '5.0'
  s.requires_arc = true
  s.source_files = 'ARNLiveBlurView/*.{h,m}'
end
