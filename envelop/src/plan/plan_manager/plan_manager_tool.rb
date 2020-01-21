# frozen_string_literal: true

module Envelop
  module PlanManagerTool
    class PlanManagerTool
      def activate
        puts 'activating PlanManagerTool...'

        reset_tool
      end

      def deactivate(view)
        puts 'deactivating PlanManagerTools...'

        view.invalidate # unsure if this is needed
      end

      def resume(view)
        puts 'resuming PlanManagerTool...'
        set_status_text
        view.invalidate
      end

      def suspend(_view)
        puts 'suspending PlanManagerTool...'
      end

      def onCancel(_reason, _view)
        Sketchup.active_model.select_tool(nil) # this will invalidate view & deactivate tool
      end

      def draw(view)
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_OPEN_HAND = 671 # open hand # put a bunch of these into some utils
      def onSetCursor
        UI.set_cursor(CURSOR_OPEN_HAND) # TODO: this totally doesn't work reliably on mac
      end

      def onMouseMove(_flags, x, y, view)
        @mouse_ip.pick(view, x, y)
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onLButtonDoubleClick(flags, x, y, view)
        image = Envelop::GeometryUtils.pick_image(view, x, y)
        if not image.nil?
          Envelop::PlanManager.hide_plan(image)
        else
          puts "Envelop::PlanMangerTool::PlanManagerTool.onLButtonDoubleClick: could not pick image from onLButtonDoubleClick."
        end
      end

      private

      def reset_tool
        # reset state
        @mouse_ip = Sketchup::InputPoint.new

        set_status_text
      end

      def set_status_text
        Sketchup.status_text = 'Drag any plan to move it along it\'s axis. Doubleclick it to hide it. "Esc" to abort.'
      end
    end

    def self.activate_plan_manager_tool
      Sketchup.active_model.select_tool(Envelop::PlanManagerTool::PlanManagerTool.new)
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
