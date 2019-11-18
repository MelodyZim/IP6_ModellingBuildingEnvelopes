require 'tempfile'

module Envelop
    module PlanImport

      # Public
      def self.show_dialog
        if @dialog && @dialog.visible?
          @dialog.bring_to_front
        else
          @dialog ||= self.create_dialog
          @dialog.add_action_callback('import_image') { |action_context, string|
            self.import_image(string)
            nil
          }
          @dialog.show
        end
      end

      private

      # Settings
      HTML_HEIGHT = 150 + 26 # TODO: verify this is correct on all platforms (+ 26 for size of title bar)

      #  Methods

      def self.create_dialog
        puts("Envelop::PlanImport.create_dialog()...")

        view = Sketchup.active_model.active_view
        html_height = Envelop::PlanImport::HTML_HEIGHT

        html_file = File.join(__dir__, 'plan_import.html')
        options = {
          :dialog_title => "Plan Import",
          :preferences_key => "envelop.planimport",
          :min_height => html_height,
          :max_height => html_height,
          :style => UI::HtmlDialog::STYLE_UTILITY
        }
        dialog = UI::HtmlDialog.new(options)
        dialog.set_file(html_file)
        dialog.set_can_close{
          false # TODO: this straight up does not work
        }
        dialog.set_size(view.vpwidth, html_height)  # TODO: update this as the window is resized & make not resizeable
        dialog.set_position(0, view.vpheight - html_height) # TODO: make it so this cannot be changed?
        dialog
      end

      def self.import_image(image_base64)
        Tempfile.create(['plan', '.png']).binmode { |file|
          f.write(Base64.decode64(image_base64['data:image/png;base64,'.length .. -1]));
          #f.rewind; # TODO ?
          model = Sketchup.active_model;
          entities = model.active_entities;
          point = Geom::Point3d.new(0,0,0);
          puts f.path;
          puts "";;
          image = entities.add_image(f.path, point, 500);
        }
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
