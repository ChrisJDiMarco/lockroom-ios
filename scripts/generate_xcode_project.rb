#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "xcodeproj"

ROOT = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "Lockroom.xcodeproj")
APP_NAME = "Lockroom"
APP_DIR = File.join(ROOT, APP_NAME)
TEST_DIR = File.join(ROOT, "LockroomTests")

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
app_target = project.new_target(:application, APP_NAME, :ios, "18.0")
test_target = project.new_target(:unit_test_bundle, "LockroomTests", :ios, "18.0")
test_target.add_dependency(app_target)

app_group = project.main_group.new_group(APP_NAME, APP_NAME)
test_group = project.main_group.new_group("LockroomTests", "LockroomTests")

def add_files(group, target, base_dir, relative_dir)
  package_paths = Dir[File.join(base_dir, relative_dir, "**", "*.xcassets")].sort
  package_paths.each do |path|
    relative_path = path.delete_prefix("#{base_dir}/")
    file_ref = group.new_reference(relative_path)
    file_ref.last_known_file_type = "folder.assetcatalog"
    target.resources_build_phase.add_file_reference(file_ref)
  end

  Dir[File.join(base_dir, relative_dir, "**", "*")].sort.each do |path|
    next if File.directory?(path)
    next if package_paths.any? { |package_path| path.start_with?("#{package_path}/") }

    relative_path = path.delete_prefix("#{base_dir}/")
    file_ref = group.new_reference(relative_path)
    if File.extname(path) == ".swift"
      target.add_file_references([file_ref])
    else
      target.resources_build_phase.add_file_reference(file_ref)
    end
  end
end

add_files(app_group, app_target, APP_DIR, "Sources")
add_files(app_group, app_target, APP_DIR, "Resources")
add_files(test_group, test_target, TEST_DIR, ".")

project.build_configurations.each do |config|
  config.build_settings["ALWAYS_SEARCH_USER_PATHS"] = "NO"
  config.build_settings["CLANG_ANALYZER_NONNULL"] = "YES"
  config.build_settings["CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION"] = "YES_AGGRESSIVE"
  config.build_settings["CLANG_CXX_LANGUAGE_STANDARD"] = "gnu++20"
  config.build_settings["CLANG_ENABLE_MODULES"] = "YES"
  config.build_settings["CLANG_ENABLE_OBJC_ARC"] = "YES"
  config.build_settings["CLANG_ENABLE_OBJC_WEAK"] = "YES"
  config.build_settings["CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING"] = "YES"
  config.build_settings["CLANG_WARN_BOOL_CONVERSION"] = "YES"
  config.build_settings["CLANG_WARN_COMMA"] = "YES"
  config.build_settings["CLANG_WARN_CONSTANT_CONVERSION"] = "YES"
  config.build_settings["CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS"] = "YES"
  config.build_settings["CLANG_WARN_DIRECT_OBJC_ISA_USAGE"] = "YES_ERROR"
  config.build_settings["CLANG_WARN_DOCUMENTATION_COMMENTS"] = "YES"
  config.build_settings["CLANG_WARN_EMPTY_BODY"] = "YES"
  config.build_settings["CLANG_WARN_ENUM_CONVERSION"] = "YES"
  config.build_settings["CLANG_WARN_INFINITE_RECURSION"] = "YES"
  config.build_settings["CLANG_WARN_INT_CONVERSION"] = "YES"
  config.build_settings["CLANG_WARN_NON_LITERAL_NULL_CONVERSION"] = "YES"
  config.build_settings["CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF"] = "YES"
  config.build_settings["CLANG_WARN_OBJC_LITERAL_CONVERSION"] = "YES"
  config.build_settings["CLANG_WARN_OBJC_ROOT_CLASS"] = "YES_ERROR"
  config.build_settings["CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER"] = "YES"
  config.build_settings["CLANG_WARN_RANGE_LOOP_ANALYSIS"] = "YES"
  config.build_settings["CLANG_WARN_STRICT_PROTOTYPES"] = "YES"
  config.build_settings["CLANG_WARN_SUSPICIOUS_MOVE"] = "YES"
  config.build_settings["CLANG_WARN_UNGUARDED_AVAILABILITY"] = "YES_AGGRESSIVE"
  config.build_settings["CLANG_WARN_UNREACHABLE_CODE"] = "YES"
  config.build_settings["CLANG_WARN__DUPLICATE_METHOD_MATCH"] = "YES"
  config.build_settings["COPY_PHASE_STRIP"] = "NO"
  config.build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = "YES"
  config.build_settings["GCC_C_LANGUAGE_STANDARD"] = "gnu17"
  config.build_settings["GCC_NO_COMMON_BLOCKS"] = "YES"
  config.build_settings["GCC_WARN_64_TO_32_BIT_CONVERSION"] = "YES"
  config.build_settings["GCC_WARN_ABOUT_RETURN_TYPE"] = "YES_ERROR"
  config.build_settings["GCC_WARN_UNDECLARED_SELECTOR"] = "YES"
  config.build_settings["GCC_WARN_UNINITIALIZED_AUTOS"] = "YES_AGGRESSIVE"
  config.build_settings["GCC_WARN_UNUSED_FUNCTION"] = "YES"
  config.build_settings["GCC_WARN_UNUSED_VARIABLE"] = "YES"
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "18.0"
  config.build_settings["SDKROOT"] = "iphoneos"
  config.build_settings["SWIFT_VERSION"] = "5.0"
end

app_target.build_configurations.each do |config|
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]"] = "NO"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["DEVELOPMENT_TEAM"] = "4X5MZ8MGH9"
  config.build_settings["DEVELOPMENT_ASSET_PATHS"] = ""
  config.build_settings["ENABLE_PREVIEWS"] = "YES"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["INFOPLIST_KEY_CFBundleDisplayName"] = "Lockroom"
  config.build_settings["INFOPLIST_KEY_LSApplicationCategoryType"] = "public.app-category.photo-video"
  config.build_settings["INFOPLIST_KEY_NSPhotoLibraryUsageDescription"] = "Lockroom reads the latest photo so your Camera-close automation can develop it."
  config.build_settings["INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription"] = "Lockroom can save finished developed frames to your library."
  config.build_settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"] = "YES"
  config.build_settings["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
  config.build_settings["INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone"] = "UIInterfaceOrientationPortrait"
  config.build_settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/Frameworks"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.jarvis.lockroom"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
  config.build_settings["SWIFT_EMIT_LOC_STRINGS"] = "YES"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
end

test_target.build_configurations.each do |config|
  config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]"] = "NO"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/Frameworks @loader_path/Frameworks"
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.jarvis.lockroom.tests"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
  config.build_settings["SWIFT_VERSION"] = "5.0"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
  config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/Lockroom.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Lockroom"
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.add_test_target(test_target)
scheme.set_launch_target(app_target)
scheme.save_as(PROJECT_PATH, APP_NAME, true)

project.save

puts "Generated #{PROJECT_PATH}"
