require 'fastlane_core'
require 'credentials_manager'

module Snapshot
  class Options
    def self.available_options
      output_directory = (File.directory?("fastlane") ? "fastlane/screenshots" : "screenshots")

      @options ||= [
        FastlaneCore::ConfigItem.new(key: :workspace,
                                     short_option: "-w",
                                     env_name: "SNAPSHOT_WORKSPACE",
                                     optional: true,
                                     description: "Path the workspace file",
                                     verify_block: proc do |value|
                                       v = File.expand_path(value.to_s)
                                       UI.user_error!("Workspace file not found at path '#{v}'") unless File.exist?(v)
                                       UI.user_error!("Workspace file invalid") unless File.directory?(v)
                                       UI.user_error!("Workspace file is not a workspace, must end with .xcworkspace") unless v.include?(".xcworkspace")
                                     end),
        FastlaneCore::ConfigItem.new(key: :project,
                                     short_option: "-p",
                                     optional: true,
                                     env_name: "SNAPSHOT_PROJECT",
                                     description: "Path the project file",
                                     verify_block: proc do |value|
                                       v = File.expand_path(value.to_s)
                                       UI.user_error!("Project file not found at path '#{v}'") unless File.exist?(v)
                                       UI.user_error!("Project file invalid") unless File.directory?(v)
                                       UI.user_error!("Project file is not a project file, must end with .xcodeproj") unless v.include?(".xcodeproj")
                                     end),
        FastlaneCore::ConfigItem.new(key: :devices,
                                     description: "A list of devices you want to take the screenshots from",
                                     short_option: "-d",
                                     type: Array,
                                     optional: true,
                                     verify_block: proc do |value|
                                       available = FastlaneCore::DeviceManager.simulators
                                       value.each do |current|
                                         unless available.any? { |d| d.name.strip == current.strip }
                                           UI.user_error!("Device '#{current}' not in list of available simulators '#{available.join(', ')}'")
                                         end
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :languages,
                                     description: "A list of languages which should be used",
                                     short_option: "-g",
                                     type: Array,
                                     default_value: ['en-US']),
        FastlaneCore::ConfigItem.new(key: :launch_arguments,
                                     env_name: 'SNAPSHOT_LAUNCH_ARGUMENTS',
                                     description: "A list of launch arguments which should be used",
                                     short_option: "-m",
                                     type: Array,
                                     default_value: ['']),
        FastlaneCore::ConfigItem.new(key: :output_directory,
                                     short_option: "-o",
                                     env_name: "SNAPSHOT_OUTPUT_DIRECTORY",
                                     description: "The directory where to store the screenshots",
                                     default_value: output_directory),
        FastlaneCore::ConfigItem.new(key: :ios_version,
                                     description: "By default, the latest version should be used automatically. If you want to change it, do it here",
                                     short_option: "-i",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :skip_open_summary,
                                     env_name: 'SNAPSHOT_SKIP_OPEN_SUMMARY',
                                     description: "Don't open the HTML summary after running _snapshot_",
                                     default_value: false,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :clear_previous_screenshots,
                                     env_name: 'SNAPSHOT_CLEAR_PREVIOUS_SCREENSHOTS',
                                     description: "Enabling this option will automatically clear previously generated screenshots before running snapshot",
                                     default_value: false,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :reinstall_app,
                                     env_name: 'SNAPSHOT_REINSTALL_APP',
                                     description: "Enabling this option will automatically uninstall the application before running it",
                                     default_value: false,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :erase_simulator,
                                     env_name: 'SNAPSHOT_ERASE_SIMULATOR',
                                     description: "Enabling this option will automatically erase the simulator before running the application",
                                     default_value: false,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :localize_simulator,
                                     env_name: 'SNAPSHOT_LOCALIZE_SIMULATOR',
                                     description: "Enabling this option will configure the Simulator's system language",
                                     default_value: false,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     env_name: 'SNAPSHOT_APP_IDENTIFIER',
                                     short_option: "-a",
                                     optional: true,
                                     description: "The bundle identifier of the app to uninstall (only needed when enabling reinstall_app)",
                                     default_value: ENV["SNAPSHOT_APP_IDENTITIFER"] || CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)),
        FastlaneCore::ConfigItem.new(key: :add_photos,
                                     env_name: 'SNAPSHOT_PHOTOS',
                                     short_option: "-j",
                                     description: "A list of photos that should be added to the simulator before running the application",
                                     type: Array,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :add_videos,
                                     env_name: 'SNAPSHOT_VIDEOS',
                                     short_option: "-u",
                                     description: "A list of videos that should be added to the simulator before running the application",
                                     type: Array,
                                     optional: true),

        # Everything around building
        FastlaneCore::ConfigItem.new(key: :buildlog_path,
                                     short_option: "-l",
                                     env_name: "SNAPSHOT_BUILDLOG_PATH",
                                     description: "The directory where to store the build log",
                                     default_value: "#{FastlaneCore::Helper.buildlog_path}/snapshot"),
        FastlaneCore::ConfigItem.new(key: :clean,
                                     short_option: "-c",
                                     env_name: "SNAPSHOT_CLEAN",
                                     description: "Should the project be cleaned before building it?",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :configuration,
                                     short_option: "-q",
                                     env_name: "SNAPSHOT_CONFIGURATION",
                                     description: "The configuration to use when building the app. Defaults to 'Release'",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :xcpretty_args,
                                     short_option: "-x",
                                     env_name: "SNAPSHOT_XCPRETTY_ARGS",
                                     description: "Additional xcpretty arguments",
                                     is_string: true,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :sdk,
                                     short_option: "-k",
                                     env_name: "SNAPSHOT_SDK",
                                     description: "The SDK that should be used for building the application",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :scheme,
                                     short_option: "-s",
                                     env_name: 'SNAPSHOT_SCHEME',
                                     description: "The scheme you want to use, this must be the scheme for the UI Tests",
                                     optional: true), # optional true because we offer a picker to the user
        FastlaneCore::ConfigItem.new(key: :number_of_retries,
                                     short_option: "-n",
                                     env_name: 'SNAPSHOT_NUMBER_OF_RETRIES',
                                     description: "The number of times a test can fail before snapshot should stop retrying",
                                     type: Integer,
                                     default_value: 1),
        FastlaneCore::ConfigItem.new(key: :stop_after_first_error,
                                     env_name: 'SNAPSHOT_BREAK_ON_FIRST_ERROR',
                                     description: "Should snapshot stop immediately after the tests completely failed on one device?",
                                     default_value: false,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :derived_data_path,
                                     short_option: "-f",
                                     env_name: "SNAPSHOT_DERIVED_DATA_PATH",
                                     description: "The directory where build products and other derived data will go",
                                     optional: true)
      ]
    end
  end
end
