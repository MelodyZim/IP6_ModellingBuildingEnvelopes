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
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_BUCKET = 647
      def onSetCursor
        UI.set_cursor(CURSOR_BUCKET) # TODO: this totally doesn't work reliably
      end

      def onMouseMove(flags, x, y, view)
        @mouse_ip.pick(view, x, y)
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        puts "Envelop::MaterialisationTool::MaterialisationTool.onLButtonDown: ..."

        face = @mouse_ip.face
        unless face.nil?
          face.material = @material
        end

    		view.invalidate
      end

      private

      def reset_tool
        # reset state
        @mouse_ip = Sketchup::InputPoint.new

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
