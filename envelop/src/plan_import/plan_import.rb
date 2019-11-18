require 'tempfile'

module Envelop
    module PlanImport

      def self.show_dialog
        if @dialog && @dialog.visible?
          @dialog.bring_to_front
        else
          @dialog ||= self.create_dialog
          @dialog.add_action_callback('import_image') { |action_context, string|
            self.import_image(string)
            nil
          }
          @dialog.add_action_callback('say') { |action_context, string|
            puts string
            nil
          }
          @dialog.show
        end
      end

      private

      def self.create_dialog
        html_file = File.join(__dir__, 'plan_import.html')
        options = {
          :dialog_title => "Plan Import",
          :preferences_key => "envelop.planimport",
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
        dialog = UI::HtmlDialog.new(options)
        dialog.set_file(html_file)
        dialog.center
        dialog
      end

      def self.import_image(image_base64)
        #Tempfile.create { |f|
        f = Tempfile.new(['plan', '.png']).binmode;
          f.write(Base64.decode64(image_base64['data:image/png;base64,'.length .. -1]));
          f.rewind; # TODO ?
          model = Sketchup.active_model;
          entities = model.active_entities;
          point = Geom::Point3d.new(0,0,0);
          puts f.path;
          puts "";;
          image = entities.add_image(f.path, point, 500);
          f.delete();
        #}
      end

      end
end
