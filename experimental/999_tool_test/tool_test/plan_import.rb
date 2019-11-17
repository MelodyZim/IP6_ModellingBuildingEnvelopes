module Envelop
  module PlanHandling
      module PlanImport

        def self.show_dialog
          if @dialog && @dialog.visible?
            @dialog.bring_to_front
          else
            @dialog ||= self.create_dialog
            @dialog.add_action_callback('add_plan') { |action_context, string|
              puts string
              nil
            }
            @dialog.show
          end
        end

        private

        def self.create_dialog
          html_file = File.join(__dir__, 'plan_import', 'plan_import.html')
          options = {
            :dialog_title => "Plan Import",
            :preferences_key => "envelop.planhandling.planimport",
            :style => UI::HtmlDialog::STYLE_DIALOG
          }
          dialog = UI::HtmlDialog.new(options)
          dialog.set_file(html_file)
          dialog.center
          dialog
        end

      end
  end
end
