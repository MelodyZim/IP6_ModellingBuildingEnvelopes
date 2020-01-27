module Envelop
  module MaterialisationTool
    class MaterialisationTool
      def initialize(material)
        @material = material
      end

      def activate
        puts 'activating MaterialisationTool...'

        reset_tool
      end

      def deactivate(view)
        puts 'deactivating MaterialisationTool...'

        # no need to reset_tool, tool instance will be discarded after this

        view.invalidate
      end

      def resume(view)
        puts 'resuming MaterialisationTool...'
        set_status_text
        view.invalidate
      end

      def suspend(_view)
        puts 'suspending MaterialisationTool...'
      end

      def onCancel(_reason, _view)
        Sketchup.active_model.select_tool(nil) # this will invalidate view & discard tool instance
      end

      def draw(view)
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_BUCKET = 647
      def onSetCursor
        UI.set_cursor(CURSOR_BUCKET) # TODO: this totally doesn't work reliably
      end

      def onLButtonDown(flags, x, y, view)
        puts "Envelop::MaterialisationTool::MaterialisationTool.onLButtonDown: ..."

        faces = Envelop::GeometryUtils.pick_all_entity(view, x, y, Sketchup::Face).map { |pr| pr.entity}
        if faces.length > 0
          faces[0].material = @material
        end

    		view.invalidate
      end

      private

      def reset_tool
        # reset state

        set_status_text
      end

      def set_status_text
        Sketchup.status_text = 'Click area to apply material. "Esc" to abort.'
      end
    end

    def self.activate_materialisation_tool(material)
      Sketchup.active_model.select_tool(Envelop::MaterialisationTool::MaterialisationTool.new(material))
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
