Pod::Spec.new do |s|
  s.name         = "DSFFullTextSearchIndex"
  s.version      = "0.95"
  s.summary      = "A simple full text search (FTS) class using SQLite FTS5 using a similar API as SKSearchKit"
  s.description  = <<-DESC
    A simple full text search (FTS) class using SQLite FTS5 using a similar API as SKSearchKit
  DESC
  s.homepage     = "https://github.com/dagronf"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Darren Ford" => "dford_au-reg@yahoo.com" }
  s.social_media_url   = ""
  s.osx.deployment_target = "10.11"
  s.ios.deployment_target = "11.4"
  s.tvos.deployment_target = "11.4"
  s.source       = { :git => ".git", :tag => s.version.to_s }
  s.subspec "Core" do |ss|
    ss.source_files  = "Sources/DSFFullTextSearchIndex/**/*.swift"
  end

  s.ios.framework  = 'UIKit'
  s.osx.framework  = 'AppKit'

  s.swift_version = "5.0"
end
