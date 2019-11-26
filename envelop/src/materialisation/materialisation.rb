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

    #  Methods

    def self.create_dialog
      puts('Envelop::Materialisation.create_dialog()...')

      height = Envelop::WindowUtils.ViewHeightPixels - Envelop::PlanImport::HTML_HEIGHT + Envelop::WindowUtils.MagicWindowSizeAndPositioningConst

      html_file = File.join(__dir__, 'materialisation.html')
      options = {
        dialog_title: 'Materialisation',
        preferences_key: 'envelop.materialisation',
        min_width: Envelop::Materialisation::HTML_WIDTH,
        max_width: Envelop::Materialisation::HTML_WIDTH,
        min_height: height,
        max_height: height,
        style: UI::HtmlDialog::STYLE_UTILITY
      }
      dialog = UI::HtmlDialog.new(options)
      dialog.set_file(html_file)
      dialog.set_can_close do
        false # TODO: this straight up does not work on Mac (Works on Windows)
      end

      dialog.set_size(Envelop::Materialisation::HTML_WIDTH, height)
      dialog.set_position(Envelop::WindowUtils.ViewWidthPixels - Envelop::Materialisation::HTML_WIDTH, Envelop::WindowUtils.SketchupMenuAndToolbarHeight)

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
