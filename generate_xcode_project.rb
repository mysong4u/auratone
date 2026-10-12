require 'xcodeproj'

project_name = 'AuraTone'
project_path = "#{project_name}.xcodeproj"

# 1. Create the project
project = Xcodeproj::Project.new(project_path)

# 2. Add the Parent iOS Application Target
ios_target = project.new_target(:application, project_name, :ios, '17.0')

# 3. Create a group for Sources
sources_group = project.main_group.new_group('Sources', 'Sources')

# 4. Find all .swift files recursively in Sources/ and add to the target
Dir.glob('Sources/**/*.swift').each do |file_path|
  file_name = file_path.sub('Sources/', '')
  file_ref = sources_group.new_reference(file_name)
  
  # Compile Swift files on the iOS target
  ios_target.source_build_phase.add_file_reference(file_ref)
end

# 5. Add Asset Catalog (Assets.xcassets)
ios_assets_ref = sources_group.new_reference('Assets.xcassets')
ios_assets_ref.last_known_file_type = 'folder.assetcatalog'
ios_target.resources_build_phase.add_file_reference(ios_assets_ref)

# 5.5. Add MIDI files from MIDI/ directory to resources
midi_group = project.main_group.new_group('MIDI', 'MIDI')
Dir.glob('MIDI/*.{mid,sf2}').each do |file_path|
  file_name = File.basename(file_path)
  file_ref = midi_group.new_reference(file_name)
  ios_target.resources_build_phase.add_file_reference(file_ref)
end

# 6. Set up Build Settings for the Parent iOS Target
ios_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.air.#{project_name}"
  config.build_settings['PRODUCT_NAME'] = project_name
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1' # iPhone Only
  config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
  config.build_settings['SKIP_INSTALL'] = 'NO'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['SDKROOT'] = 'iphoneos' # Force iOS SDK
  config.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator' # Set iOS platforms
  config.build_settings['MARKETING_VERSION'] = '1.0.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['INFOPLIST_KEY_CFBundleIconName'] = 'AppIcon'
  config.build_settings['INFOPLIST_KEY_UIRequiredDeviceCapabilities'] = 'arm64'
  config.build_settings['INFOPLIST_KEY_ITSAppUsesNonExemptEncryption'] = 'NO'
end

# 7. Save the project
project.save
puts "Xcode project generated at #{project_path}"
