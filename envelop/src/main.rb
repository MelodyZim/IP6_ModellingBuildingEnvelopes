require_relative 'utils/camera_utils/camera_utils'
require_relative 'utils/window_utils/window_utils'
require_relative 'plan/plan_import/plan_import'
require_relative 'plan/plan_edit/plan_edit'
require_relative 'plan/plan_position/plan_position'
require_relative 'plan/plan_position/plan_position_tool'
require_relative 'plan/plan_manager/plan_manager'
require_relative 'modeling/housekeeper/housekeeper'
require_relative 'modeling/materialisation/materialisation'
require_relative 'modeling/materialisation/materialisation_tool'
require_relative 'modeling/materialisation/materialisation_dialog'
require_relative 'modeling/modeling_tool/modeling_tool'
require_relative 'modeling/floor_maker_tool/floor_maker_tool'
require_relative 'modeling/scale/scale_tool'
require_relative 'output/area_output/area_output'
require_relative 'ui/toolbar/toolbar'

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
  end
end
