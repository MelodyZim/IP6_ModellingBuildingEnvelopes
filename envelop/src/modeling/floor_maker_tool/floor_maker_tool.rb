# frozen_string_literal: true

module Envelop
  module FloorMakerTool
    class FloorMakerTool < Envelop::ToolUtils::AbstractTool
      def initialize
        super(PenTool, cursor_id: Envelop::ToolUtils::CURSOR_PENCIL)
      end

      def draw(view)
        super(view)

        draw_preview(view) if @ip.valid?
      end

      def onLButtonDown(flags, x, y, view)
        super(flags, x, y, view)

        if @ip.valid?

          remove_preview
          Envelop::OperationUtils.operation_chain('Envelop: New floor at mouseclick', false, lambda {
            return split_house_at(Envelop::Housekeeper.get_house)
          })
          redraw

        else
          UI.messagebox('Could not make floor because current mouse position is invalid.')
        end
      end

      private

      # Settings
      FOR_SURE_OUTSIDE_MODEL = 999_999_999

      def split_house_at(target_grp, height = @ip.position.z)
        return false if target_grp.nil?

        entities = Sketchup.active_model.active_entities

        intersect_plane = entities.add_face([FOR_SURE_OUTSIDE_MODEL, FOR_SURE_OUTSIDE_MODEL, height], [FOR_SURE_OUTSIDE_MODEL, -FOR_SURE_OUTSIDE_MODEL, height], [-FOR_SURE_OUTSIDE_MODEL, -FOR_SURE_OUTSIDE_MODEL, height], [-FOR_SURE_OUTSIDE_MODEL, FOR_SURE_OUTSIDE_MODEL, height])
        return false if intersect_plane.nil?

        intersect_group = entities.add_group(intersect_plane)

        house_group = Envelop::Housekeeper.get_house
        return false if house_group.nil?

        house_group.entities.intersect_with(true, house_group.transformation, target_grp.entities, house_group.transformation, true, intersect_group)

        intersect_group.erase!
        return true
      end

      def set_status_text
        Sketchup.status_text = 'Click anywhere to create floor separation at that elevation. `Esc` to abort.'
      end

      def draw_preview(view)
          remove_preview
          Envelop::OperationUtils.operation_chain('Envelop: Split House Preview', true, lambda {

              new_grp = Sketchup.active_model.active_entities.add_group
              split_house_at(new_grp)

              house_group = Envelop::Housekeeper.get_house
              entities = Sketchup.active_model.active_entities
              new_grp.entities.grep(Sketchup::Edge).each do |edge|
                start_p = Geom::Point3d.new(edge.start)
                start_p.transform! house_group.transformation
                end_p = Geom::Point3d.new(edge.end)
                end_p.transform! house_group.transformation
                line = entities.add_cline(start_p, end_p)
                line.set_attribute("Envelop::FoolMakerTool", "isPreview", true)
                edge.erase!
              end
          })
      end

      def remove_preview
        Envelop::OperationUtils.operation_chain('Envelop: Split House Renove Preview', true, lambda {
          Sketchup.active_model.active_entities.grep(Sketchup::ConstructionLine).each do |cline|
            isPreview = cline.get_attribute("Envelop::FoolMakerTool", "isPreview", false)
            if isPreview
              cline.erase!
            end
          end
        })
      end

      def reset_tool
        super
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
