require_relative 'module'

require_relative 'storage'
require_relative 'encryption'

module Match
  # These functions should only be used while in (UI.) interactive mode
  class ChangePassword
    def self.update(params: nil)
      if params[:storage_mode] != "git"
        # Only git supports changing the password
        # All other storage options will most likely use more advanced
        # ways to encrypt files
        UI.user_error!("Only git-based match allows you to change your password, current `storage_mode` is #{params[:storage_mode]}")
      end

      ensure_ui_interactive

      new_password = FastlaneCore::Helper.ask_password(message: "New passphrase for Git Repo: ", confirm: true)

      # Choose the right storage and encryption implementations
      storage = Storage.for_mode(params[:storage_mode], {
        git_url: params[:git_url],
        shallow_clone: params[:shallow_clone],
        skip_docs: params[:skip_docs],
        git_branch: params[:git_branch],
        git_full_name: params[:git_full_name],
        git_user_email: params[:git_user_email],
        clone_branch_directly: params[:clone_branch_directly]
      })
      storage.download

      encryption = Encryption.for_storage_mode(params[:storage_mode], {
        git_url: params[:git_url],
        working_directory: storage.working_directory
      })
      encryption.decrypt_files

      encryption.clear_password
      encryption.store_password(new_password)

      message = "[fastlane] Changed passphrase"
      files_to_commit = encryption.encrypt_files(password: new_password)
      storage.save_changes!(files_to_commit: files_to_commit, custom_message: message)
    end

    def self.ensure_ui_interactive
      raise "This code should only run in interactive mode" unless UI.interactive?
    end

    private_class_method :ensure_ui_interactive
  end
end
