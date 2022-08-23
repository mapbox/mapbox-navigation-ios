module Snapshot
  # Responsible for collecting the generated screenshots and copying them over to the output directory
  class Collector
    # Returns true if it succeeds
    def self.fetch_screenshots(output, dir_name, device_type, launch_arguments_index)
      # Documentation about how this works in the project README
      containing = File.join(TestCommandGenerator.derived_data_path, "Logs", "Test")
      attachments_path = File.join(containing, "Attachments")

      to_store = attachments(containing)
      matches = output.scan(/snapshot: (.*)/)

      if to_store.count == 0 && matches.count == 0
        return false
      end

      if matches.count != to_store.count
        UI.error "Looks like the number of screenshots (#{to_store.count}) doesn't match the number of names (#{matches.count})"
      end

      matches.each_with_index do |current, index|
        name = current[0]
        filename = to_store[index]

        language_folder = File.join(Snapshot.config[:output_directory], dir_name)
        FileUtils.mkdir_p(language_folder)

        device_name = device_type.delete(" ")
        components = [device_name, launch_arguments_index, name].delete_if { |a| a.to_s.length == 0 }

        output_path = File.join(language_folder, components.join("-") + ".png")
        from_path = File.join(attachments_path, filename)
        if $verbose
          UI.success "Copying file '#{from_path}' to '#{output_path}'..."
        else
          UI.success "Copying '#{output_path}'..."
        end
        FileUtils.cp(from_path, output_path)
      end

      return true
    end

    def self.attachments(containing)
      UI.message "Collecting screenshots..."
      plist_path = Dir[File.join(containing, "*.plist")].last # we clean the folder before each run
      return attachments_in_file(plist_path)
    end

    def self.attachments_in_file(plist_path)
      UI.verbose "Loading up '#{plist_path}'..."
      report = Plist.parse_xml(plist_path)

      to_store = [] # contains the names of all the attachments we want to use

      report["TestableSummaries"].each do |summary|
        (summary["Tests"] || []).each do |test|
          (test["Subtests"] || []).each do |subtest|
            (subtest["Subtests"] || []).each do |subtest2|
              (subtest2["Subtests"] || []).each do |subtest3|
                (subtest3["ActivitySummaries"] || []).each do |activity|
                  check_activity(activity, to_store)
                end
              end
            end
          end
        end
      end

      UI.message "Found #{to_store.count} screenshots..."
      UI.verbose "Found #{to_store.join(', ')}"
      return to_store
    end

    def self.check_activity(activity, to_store)
      # On iOS, we look for the "Unknown" rotation gesture that signals a snapshot was taken here.
      # On tvOS, we look for "Browser" count.
      # These are both events that are not normally triggered by UI testing, making it easy for us to
      # locate where snapshot() was invoked.
      if activity["Title"] == "Set device orientation to Unknown" || activity["Title"] == "Get number of matches for: Children matching type Browser"
        if activity["Attachments"]
          to_store << activity["Attachments"].last["FileName"]
        else # Xcode 7.3 has stopped including 'Attachments', so we synthesize the filename manually
          to_store << "Screenshot_#{activity['UUID']}.png"
        end
      end
      (activity["SubActivities"] || []).each do |subactivity|
        check_activity(subactivity, to_store)
      end
    end
  end
end
