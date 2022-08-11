#
# Be sure to run `pod lib lint ZNetDiagnosis.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZNetDiagnosis'
  s.version          = '1.0.0'
  s.summary          = 'Z Net Diagnosis.'
  s.description      = <<-DESC
  Z Net Diagnosis.
                       DESC
  s.homepage         = 'https://github.com/lZackx/ZNetDiagnosis'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lZackx' => 'lzackx@lzackx.com' }
  s.source           = { :git => 'https://github.com/lZackx/ZNetDiagnosis.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.default_subspecs = 'All'

  s.subspec "All" do |ss|
    ss.dependency "ZNetDiagnosis/Core"
    ss.dependency "ZNetDiagnosis/Reachability"
    ss.dependency "ZNetDiagnosis/Ping"
    ss.dependency "ZNetDiagnosis/Traceroute"
    ss.dependency "ZNetDiagnosis/DNS"
    ss.dependency "ZNetDiagnosis/Port"
    ss.dependency "ZNetDiagnosis/Lan"
  end

  s.subspec "Core" do |ss|
    ss.source_files = "ZNetDiagnosis/Classes/core/**/*"
  end

  s.subspec "Reachability" do |ss|
    ss.source_files = "ZNetDiagnosis/Classes/reachability/**/*"
    ss.dependency "ZNetDiagnosis/Core"
  end

  s.subspec "DNS" do |ss|
    ss.source_files = "ZNetDiagnosis/Classes/dns/**/*"
    ss.dependency "ZNetDiagnosis/Core"
    ss.libraries = [
      'resolv'
    ]
  end

  s.subspec "Ping" do |ss|
    ss.source_files = "ZNetDiagnosis/Classes/ping/**/*"
    ss.dependency "ZNetDiagnosis/Core"
  end

  s.subspec "Traceroute" do |ss|
    ss.source_files = "ZNetDiagnosis/Classes/traceroute/**/*"
    ss.dependency "ZNetDiagnosis/Core"
    ss.dependency "ZNetDiagnosis/DNS"
  end

  s.subspec "Port" do |ss|
    ss.source_files = "ZNetDiagnosis/Classes/port/**/*"
    ss.dependency "ZNetDiagnosis/Core"
  end

  s.subspec "Lan" do |ss|
    ss.source_files = "ZNetDiagnosis/Classes/lan/**/*"
    ss.dependency "ZNetDiagnosis/Core"
  end

end
