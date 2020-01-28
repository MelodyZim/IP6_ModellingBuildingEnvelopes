# frozen_string_literal: true

require_relative '../vendor/rb/os'

module Envelop
  module DialogUtils
    # Public
    def self.close_dialog(id)
      if @dialogs[id].nil?
        warn "Envelop::DialogUtils.close_dialog: could not find dialog with ID #{id}."
      else
        @dialogs[id].close
      end
    end

    def self.execute_script(id, execute_script_parameter)
      if @dialogs[id].nil?
        warn "Envelop::DialogUtils.execute_script: could not find dialog with ID #{id}."
      else
        @dialogs[id].execute_script(execute_script_parameter)
      end
    end

    def self.show_dialog(dialog_options, &attach_callbacks_callback)
      if @dialogs[dialog_options[:id]]&.visible?
        @dialogs[dialog_options[:id]].bring_to_front
      else
        if @dialogs[dialog_options[:id]].nil?
          @dialogs[dialog_options[:id]] = create_dialog(dialog_options)
        end

        attach_callbacks_callback.call(@dialogs[dialog_options[:id]])
        @dialogs[dialog_options[:id]].show
      end
    end

    # Private
    def self.preferences_key_file_path(id)
      File.join(__dir__, 'prefs', id.gsub(/[^0-9A-Z]/i, '_') + '.exists')
    end

    def self.exists_preferences_key_file(id)
      path = preferences_key_file_path(id)

      # if OS.mac?
      #   @existing_preferences_key_files.include?(path)
      # else
        File.exist?(path)
      # end
    end

    def self.create_preferences_key_file(id)
      path = preferences_key_file_path(id)

      # if OS.mac?
      #   # mac only saves these settings per session
      #   unless @existing_preferences_key_files.include?(path)
      #     @existing_preferences_key_files.push(path)
      #   end
      #
      # else
        dir = File.dirname(path)
        Dir.mkdir(dir) unless Dir.exist?(dir)

        File.open(path, 'w') {} unless File.exist?(path)
      # end
    end

    def self.create_dialog(path_to_html:, title:, id:, height:, width:, pos_x:, pos_y:,
                           center: false, can_close: false, resizeable_height: false, resizeable_width: false, min_height: 0, min_width: 0, dont_save_prefs: false)
      options = {
        dialog_title: title,
        style: UI::HtmlDialog::STYLE_UTILITY
      }

      options[:preferences_key] = id unless dont_save_prefs

      options_not_resizeable_height = {
        min_height: height,
        max_height: height
      }
      options_not_resizeable_width = {
        min_width: width,
        max_width: width
      }
      unless resizeable_height
        options = options_not_resizeable_height.merge(options)
      end
      unless resizeable_width
        options = options_not_resizeable_width.merge(options)
      end

      if resizeable_height && (min_height != 0)
        options[:min_height] = min_height
      end
      options[:min_width] = min_width if resizeable_width && (min_width != 0)

      dialog = UI::HtmlDialog.new(options)
      dialog.set_file(path_to_html)
      dialog.set_can_close do
        can_close # TODO: this straight up does not work on Mac (Works on Windows) #TODO allow some dialogs to be closeable if appropriate
      end

      if dont_save_prefs || !exists_preferences_key_file(id) # TODO: update this as the main window is resized. # TODO: ensure window cannot be repositioned, but it needs to be able to be managed/hidden in some way
        dialog.set_size(width, height)
        dialog.set_position(pos_x, pos_y)
      end

      dialog.center if center

      create_preferences_key_file(id) unless dont_save_prefs

      dialog
    end

    def self.reload
      @dialogs&.each_value do |dialog|
        dialog&.close
      end

      @dialogs = {}
    end
    reload

    unless file_loaded?(__FILE__)
      puts "resetting @existing_preferences_key_files"
      @existing_preferences_key_files = [] if OS.mac?

      file_loaded(__FILE__)
    end
  end
end
