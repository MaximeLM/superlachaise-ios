platform :ios, '10.0'

target 'SuperLachaise' do
  use_frameworks!

  pod 'RealmSwift'
  pod 'RxSwift'
  pod 'RxCocoa'

end

pod 'SwiftLint'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
    end
  end
end
