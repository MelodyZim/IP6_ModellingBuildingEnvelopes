# frozen_string_literal: true

module Envelop
  module FloorMakerTool
    class FloorMakerTool
      def initialize; end

      def activate
        puts 'activating FloorMakerTool...'

        reset_tool
      end

      def deactivate(view)
        puts 'deactivating FloorMakerTool...'

        # no need to reset_tool, tool instance will be discarded after this

        view.invalidate
      end

      def resume(view)
        puts 'resuming FloorMakerTool...'
        set_status_text
        view.invalidate
      end

      def suspend(_view)
        puts 'suspending FloorMakerTool...'
      end

      def onCancel(_reason, _view)
        Sketchup.active_model.select_tool(nil) # this will invalidate view & discard tool instance
      end

      def draw(view)
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        UI.set_cursor(CURSOR_PENCIL) # TODO: this totally doesn't work reliably on mac
      end

      def onMouseMove(_flags, x, y, view)
        @mouse_ip.pick(view, x, y)
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onLButtonDown(_flags, _x, _y, view)
        puts 'Envelop::MaterialisationTool::FloorMakerTool.onLButtonDown: ...'

        if @mouse_ip.valid?
          model = Sketchup.active_model
          model.start_operation('Envelop: New floor at mouseclick', true)

          split_house_at(@mouse_ip.position.z)

          model.commit_operation # TODO: dont if aborted/unsucessfull

        else
          UI.messagebox('Could not make floor because current mouse position is invalid InputPosition.')
        end

        view.invalidate # TODO: is this rally needed in the else case?
      end

      private

      # Settings
      FOR_SURE_OUTSIDE_MODEL = 999_999_999

      def split_house_at(height)

        entities = Sketchup.active_model.active_entities

        intersect_plane = entities.add_face([FOR_SURE_OUTSIDE_MODEL, FOR_SURE_OUTSIDE_MODEL, height], [FOR_SURE_OUTSIDE_MODEL, -FOR_SURE_OUTSIDE_MODEL, height], [-FOR_SURE_OUTSIDE_MODEL, -FOR_SURE_OUTSIDE_MODEL, height], [-FOR_SURE_OUTSIDE_MODEL, FOR_SURE_OUTSIDE_MODEL, height])
        intersect_group = entities.add_group(intersect_plane)

        house_group = Envelop::Housekeeper.get_house

        house_group.entities.intersect_with(true, house_group.transformation, house_group.entities, house_group.transformation, true, intersect_group)

        intersect_group.erase!
      end

      def reset_tool
        # reset state
        @mouse_ip = Sketchup::InputPoint.new

        set_status_text
      end

      def set_status_text
        Sketchup.status_text = 'Click anywhere to create floor separation at that elevation. "Esc" to abort.'
      end
    end

    def self.activate_floor_maker_tool
      Sketchup.active_model.select_tool(Envelop::FloorMakerTool::FloorMakerTool.new)
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
