require_relative 'plan_import/plan_import'
require_relative 'plan_edit/plan_edit'
require_relative 'camera_utils/camera_utils'

module Envelop
  module Main
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

  end
end
