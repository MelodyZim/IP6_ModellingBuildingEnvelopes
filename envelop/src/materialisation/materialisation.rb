# frozen_string_literal: true

module Envelop
  module Materialisation
    # Public
    def self.show_dialog
      if @dialog&.visible?
        @dialog.bring_to_front
      else
        @dialog ||= create_dialog
        @dialog.show
      end
    end

        private

    # Settings
    HTML_WIDTH = 200
    # FOOTER_HEIGHT = 30 TODO: is this not needed on all platforms
    # HEADER_HEIGHT = 65
    # HTML_HEIGHT_REDUCTION = FOOTER_HEIGHT + HEADER_HEIGHT #30 for footer,  65 for header. TODO: is this correct on all platforms?

    #  Methods

    def self.create_dialog
      puts('Envelop::Materialisation.create_dialog()...')

      view = Sketchup.active_model.active_view

      viewHeight = Envelop::WindowUtils.ViewHeightPixels
      viewWidth = Envelop::WindowUtils.ViewWidthPixels

      html_width = Envelop::Materialisation::HTML_WIDTH

      html_file = File.join(__dir__, 'materialisation.html')
      options = {
        dialog_title: 'Materialisation',
        preferences_key: 'envelop.materialisation',
        min_width: html_width,
        max_width: html_width,
        style: UI::HtmlDialog::STYLE_UTILITY
      }
      dialog = UI::HtmlDialog.new(options)
      dialog.set_file(html_file)
      dialog.set_can_close do
        false # TODO: this straight up does not work on Mac (Works on Windows)
      end
       # TODO: update this as the window is resized & make not resizeable
      dialog.set_size(html_width, viewHeight - Envelop::PlanImport::HTML_HEIGHT + 8)
      #dialog.center # TODO: position calculation wrong on windows
           if OS.mac? 
          header_height = 88
      elsif OS.windows?
          header_height =  77
      else
          puts "Usupported Platfrom, sizing and positioning of dialogs is unlikely to work"
      end
      dialog.set_position(viewWidth - html_width, header_height) # - html_width, 88) # TODO: make it so this cannot be changed?

      dialog
    end

    def self.reload
      if @dialog
        @dialog.close
        remove_instance_variable(:@dialog)
      end
    end
    reload
  end
end
