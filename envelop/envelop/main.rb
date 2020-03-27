Sketchup.require "#{File.dirname(__FILE__)}/utils/camera_utils"
Sketchup.require "#{File.dirname(__FILE__)}/utils/window_utils"
Sketchup.require "#{File.dirname(__FILE__)}/utils/dialog_utils"
Sketchup.require "#{File.dirname(__FILE__)}/utils/observer_utils"
Sketchup.require "#{File.dirname(__FILE__)}/utils/operation_utils"
Sketchup.require "#{File.dirname(__FILE__)}/utils/geometry_utils"
Sketchup.require "#{File.dirname(__FILE__)}/utils/tool_utils"
Sketchup.require "#{File.dirname(__FILE__)}/plan/plan_import/plan_import"
Sketchup.require "#{File.dirname(__FILE__)}/plan/plan_edit/plan_edit"
Sketchup.require "#{File.dirname(__FILE__)}/plan/plan_position/plan_position"
Sketchup.require "#{File.dirname(__FILE__)}/plan/plan_position/plan_position_tool"
Sketchup.require "#{File.dirname(__FILE__)}/plan/plan_manager/plan_manager"
Sketchup.require "#{File.dirname(__FILE__)}/plan/plan_manager/plan_manager_tool"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/housekeeper/housekeeper"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/materialisation/dialog/materialisation_dialog"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/materialisation/materialisation/material_ops"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/materialisation/materialisation/default_material"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/materialisation/materialisation/material_colors"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/materialisation/materialisation/material_hash"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/materialisation/materialisation/material_management"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/materialisation/materialisation/tmp_material"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/materialisation/materialisation_tool"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/floor_maker_tool/floor_maker_tool"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/scale/scale_tool"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/orientation/orientation_tool"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/pen/pen_tool"
Sketchup.require "#{File.dirname(__FILE__)}/modeling/push-pull/push-pull_tool"
Sketchup.require "#{File.dirname(__FILE__)}/output/area_output/area_output"
Sketchup.require "#{File.dirname(__FILE__)}/ui/wizard/wizard"
Sketchup.require "#{File.dirname(__FILE__)}/ui/toolbar/toolbar"

module Envelop
  module Main
    OPEN_DIALOGS_AFTER_LOAD = TRUE

    SCALING = 1

    # TODO: find out if this has to be editable
    NORTH = Y_AXIS
    UP = Z_AXIS

    def self.Up
      UP
    end
    def self.Down
      self.Up.reverse
    end

    def self.North
      NORTH
    end
    def self.East
      self.West.reverse
    end
    def self.South
      self.North.reverse
    end
    def self.West
      trans = Geom::Transformation.rotation(Geom::Point3d.new, self.Up, 90.degrees)
      self.North.transform(trans)
    end

    def self.show_dialogs
      Envelop::PlanImport.show_dialog
      Envelop::MaterialisationDialog.show_dialog
    end

    def self.delete_marc
      Sketchup.active_model.entities.each do |entity|
        if entity.is_a?(Sketchup::ComponentInstance) && entity.definition.name == "Marc"
          entity.erase!
        end
      end
    end

    delete_marc
    Envelop::Main.show_dialogs
  end
end
