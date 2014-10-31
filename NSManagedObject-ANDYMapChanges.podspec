Pod::Spec.new do |s|
s.name             = "NSManagedObject-ANDYMapChanges"
s.version          = "0.1"
s.summary          = "A short description of NSManagedObject-ANDYMapChanges."
s.description      = <<-DESC
An optional longer description of NSManagedObject-ANDYMapChanges

* Markdown format.
* Don't worry about the indent, we strip it!
DESC
s.homepage         = "https://github.com/nselvis/NSManagedObject-ANDYMapChanges"
s.license          = 'MIT'
s.author           = { "Elvis Nuñez" => "hello@nselvis.com" }
s.source           = { :git => "https://github.com/nselvis/NSManagedObject-ANDYMapChanges.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/nselvis'

s.platform     = :ios, '7.0'
s.requires_arc = true

s.source_files = 'Source/**/*'

s.frameworks = 'Foundation'
end
