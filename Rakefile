desc "Runs unit tests for iOS"
task :test do
  sh("xcodebuild -workspace ZCREasyBake.xcworkspace -scheme ZCREasyBake -destination 'platform=iOS Simulator,name=iPhone Retina (4-inch)' -configuration Release clean build test | xcpretty -c && exit ${PIPESTATUS[0]}") rescue nil
end

task :default => :test

