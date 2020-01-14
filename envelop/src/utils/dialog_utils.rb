# frozen_string_literal: true

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
    def self.create_dialog(path_to_html:, title:, id:, height:, width:, pos_x:, pos_y:,
                           center: false, can_close: false, resizeable_height: false, resizeable_width: false, min_height: 0, min_width: 0)
      options = {
        dialog_title: title,
        preferences_key: id,
        style: UI::HtmlDialog::STYLE_UTILITY
      }

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

      dialog.set_size(width, height) # TODO: update this as the main window is resized.
      dialog.set_position(pos_x, pos_y) # TODO: update this as the main window is resized. # TODO: ensure window cannot be repositioned, but it needs to be able to be managed/hidden in some way

      dialog.center if center

      dialog
    end

    def self.reload
      if @dialogs
        @dialogs.each_value do |dialog|
          dialog&.close
        end
        remove_instance_variable(:@dialogs)
      end

      @dialogs = {}
    end
    reload
  end
end
