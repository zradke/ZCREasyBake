namespace :test do
  desc "Runs unit tests for iOS"
  task :ios do
    run_tests('ZCREasyBakeTests-iOS', 'platform=iOS Simulator,name=iPhone Retina (4-inch)');
  end

  desc "Runs unit tests for OSX"
  task :osx do
    run_tests('ZCREasyBakeTests-OSX', 'platform=OS X');
  end
end

desc "Runs unit tests for both iOS and OSX"
task :test do
  Rake::Task['test:ios'].invoke
  Rake::Task['test:osx'].invoke
end

task :default => :test

private

def run_tests(scheme, destination)
  sh("xcodebuild -workspace ZCREasyBake.xcworkspace -scheme '#{scheme}' -destination '#{destination}' -configuration Release clean build test | xcpretty -c && exit ${PIPESTATUS[0]}") rescue nil
end

