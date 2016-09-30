Pod::Spec.new do |s|
s.name             = "DATAFilter"
s.version          = "1.0.1"
s.summary          = "Filter inserts, updates and deletions from your JSON response"
s.description      = <<-DESC
Filters inserts, updates and deletions from your JSON response.
Returns every insert and update in a block, handles deletions and uniquing internally.
DESC
s.homepage         = "https://github.com/SyncDB/DATAFilter"
s.license          = 'MIT'
s.author           = { "SyncDB" => "syncdb.contact@gmail.com" }
s.source           = { :git => "https://github.com/SyncDB/DATAFilter.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/Sync_DB'
s.ios.deployment_target = '8.0'
s.osx.deployment_target = '10.9'
s.watchos.deployment_target = '2.0'
s.tvos.deployment_target = '9.0'
s.requires_arc = true
s.source_files = 'Sources/**/*'
s.frameworks = 'Foundation', 'CoreData'
s.dependency 'DATAObjectIDs', '~> 0.6.1'
end
