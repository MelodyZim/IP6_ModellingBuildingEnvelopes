# frozen_string_literal: true

module Envelop
  module OrientationTool
    class OrientationTool
      # 2D points of the "north" indicator
      INDICATOR_POINTS = [[0, 0], [0.5, -0.5], [0, 1], [0, 0], [-0.5, -0.5], [0, 1]]

      def initialize(proceedToOutput = false)
        @proceedToOutput = proceedToOutput
      end

      def activate
        puts 'activating ScaleTool...'
        reset_tool
      end

      def deactivate(view)
        puts 'deactivating ScaleTool...'

        # no need to reset_tool, tool instance will be discarded after this

        view.invalidate
      end

      def resume(view)
        # puts 'resuming ScaleTool...'

        set_status_text
        view.invalidate
      end

      def suspend(_view)
        # puts 'suspending ScaleTool...'
      end

      def onCancel(_reason, _view)
        reset_tool
      end

      def draw(view)
        if @first_point.valid?
          Envelop::GeometryUtils.draw_lines(view, "Cyan", *get_transformed_indicator_points)
        end

        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      def getExtents
        if @first_point.valid?
          bb = Geom::BoundingBox.new
          bb.add(get_transformed_indicator_points)
          bb
        end
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        UI.set_cursor(CURSOR_PENCIL)
      end

      def onMouseMove(_flags, x, y, view)
        @mouse_ip.pick(view, x, y)
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onLButtonDown(_flags, _x, _y, view)
        if @mouse_ip.valid?
          if @first_point.valid?
            # finish

            north = compute_north(@first_point, @mouse_ip).normalize
            puts "north: #{north}"
            # TODO: set attribute on house with north

            reset_tool
            view.invalidate
          else
            # set start point
            @first_point.copy!(@mouse_ip)
            set_status_text
          end
        end
      end

      #
      # @param ip1 [Sketchup::InputPoint]
      # @param ip2 [Sketchup::InputPont]
      # @return [Geom::Vector3d]
      #
      def compute_north(ip1, ip2)
        a = ip1.position
        b = ip2.position

        # project second point to x/y plane
        b.z = a.z

        vector = b - a
        angle = Math.atan2(vector.y, vector.x)
        length = vector.length.to_f

        # snap to 22.5 degree increments
        n = 1 / 22.5.degrees
        angle = (angle * n).round / n

        Geom::Vector3d.new(Math.cos(angle) * length, Math.sin(angle) * length, vector.z)
      end

      def get_transformed_indicator_points
        if @first_point.valid?
          origin = @first_point.position
          north = compute_north(@first_point, @mouse_ip)

          # rotate north by 90 degrees
          east = Geom::Vector3d.new(north.y, -north.x, 0)

          # transform points
          INDICATOR_POINTS.map do |p| 
            origin + Envelop::GeometryUtils.vec_mul(east, p[0]) + Envelop::GeometryUtils.vec_mul(north, p[1])
          end
        end
      end

      def reset_tool
        # reset state
        @mouse_ip = Sketchup::InputPoint.new
        @first_point = Sketchup::InputPoint.new

        set_status_text
      end

      def set_status_text
        if @first_point.valid?
          Sketchup.status_text = 'Click to define north direction'
        else
          Sketchup.status_text = 'Click to select start point'
        end
      end
    end

    def self.is_model_oriented
      Sketchup.active_model.get_attribute('Envelop::OrientationTool', 'modelIsOriented', false)
    end

    def self.activate_orientation_tool(proceedToOutput = false)
      Sketchup.active_model.select_tool(Envelop::OrientationTool::OrientationTool.new(proceedToOutput))
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
