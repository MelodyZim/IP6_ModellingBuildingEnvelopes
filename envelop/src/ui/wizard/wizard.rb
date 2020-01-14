
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

    DETAIL_DIALOG_OPTIONS = {
      path_to_html: File.join(__dir__, 'wizard_detail.html'),
      title: 'Wizard Detail',
      id: 'Envelop::Wizard:WizardDetail',
      height: 600, width: 500,
      pos_x: 0, pos_y: 0,
      can_close: true,
      center: true,
      resizeable_height: true,
      resizeable_width: true
    }

    def self.attach_callbacks(dialog)
      dialog.add_action_callback("call_set_content") { |action_context|
        Envelop::DialogUtils.execute_script(DIALOG_OPTIONS[:id], "set_content('#{load_content().to_json}')")
        nil
      }
      dialog.add_action_callback("show_detail") { |action_context, number|
        Envelop::DialogUtils.show_dialog(DETAIL_DIALOG_OPTIONS) { |dialog| attach_detail_callbacks(number, dialog) }
        nil
      }
    end

    def self.attach_detail_callbacks(number, dialog)
      dialog.add_action_callback("call_set_content") { |action_context|
        Envelop::DialogUtils.execute_script(DETAIL_DIALOG_OPTIONS[:id], "set_content('#{load_detail_content(number).to_json}')")
        nil
      }
      dialog.add_action_callback("close") { |action_context|
        Envelop::DialogUtils.close_dialog(DETAIL_DIALOG_OPTIONS[:id])
        nil
      }
    end

    def self.content_path
      File.join(__dir__, 'wizard.json')
    end

    def self.load_detail_content(number)
      content = JSON.parse(File.read(content_path))
      return content['details'].find { |detail| detail['forNumber'] == number }
    end

    def self.load_content
      return JSON.parse(File.read(content_path))
    end
  end
end
