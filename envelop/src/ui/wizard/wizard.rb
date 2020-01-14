
require 'json'

module Envelop
  module Wizard
		# public
		def self.open_dialog()
      Envelop::DialogUtils.show_dialog(DIALOG_OPTIONS) { |dialog| attach_callbacks(dialog) }
		end

		private

    # settings
    HTML_HEIGHT = Envelop::WindowUtils.view_height_pixels - Envelop::PlanImport::HTML_HEIGHT + Envelop::WindowUtils.magic_window_size_and_positioning_const
    HTML_WIDTH = Envelop::WindowUtils.html_window_horirontal_scrollbar_width + 200

    DIALOG_OPTIONS = {
      path_to_html: File.join(__dir__, 'wizard.html'),
      title: 'Wizard',
      id: 'Envelop::Wizard:Wizard',
      height: HTML_HEIGHT, width: HTML_WIDTH,
      pos_x: 0, pos_y: Envelop::WindowUtils.sketchup_menu_and_toolbar_height,
      can_close: true,
      resizeable_height: true
    }

    def self.attach_callbacks(dialog)
      dialog.add_action_callback("call_set_content") { |action_context|
        Envelop::DialogUtils.execute_script(DIALOG_OPTIONS[:id], "set_content('#{load_content().to_json}')")
        nil
      }
      dialog.add_action_callback("close") { |action_context|
        Envelop::DialogUtils.close_dialog(DIALOG_OPTIONS[:id])
        nil
      }
    end

    def self.content_path
      File.join(__dir__, 'wizard.json')
    end

    def self.load_content
      return JSON.parse(File.read(content_path))
    end
  end
end
