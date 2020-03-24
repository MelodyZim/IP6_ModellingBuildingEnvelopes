# frozen_string_literal: true

module Envelop
  module OrientationTool
    class OrientationTool
      # 2D points of the "north" indicator
      ARROW = [[0, 0], [0.5, -0.5], [0, 1], [0, 0], [-0.5, -0.5], [0, 1]]

      def initialize(&complete_callback)
        @complete_callback = complete_callback
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

      def onCancel(_reason, view)
        reset_tool
        view.invalidate
      end

      def draw(view)
        main_color = "Blue"
        if @first_point.valid?
          Envelop::GeometryUtils.draw_lines(view, main_color, *get_transformed_indicator_points)
          view.draw(GL_POLYGON, *get_transformed_indicator_points)

          north = compute_north(@first_point, @mouse_ip)
          east = Geom::Vector3d.new(north.y, -north.x, 0)

          # text
          labels = Hash[
            "N" => @first_point.position + north,
            "O" => @first_point.position + east,
            "S" => @first_point.position - north,
            "W" => @first_point.position - east]

          options = {
            :size => 40,
            :align => TextAlignCenter,
          }

          labels.each do |text, position|
            draw_text(view, view.screen_coords(position), text, options)
            view.draw_points(position, 10, 2)
          end

          # circle
          subdivision = 100
          radius = north.length.to_f
          circle_Points = Array.new(subdivision) do |i|
            angle = (i * Math::PI * 2) / subdivision
            Geom::Point3d.new(Math.cos(angle) * radius, Math.sin(angle) * radius, 0)
          end
          circle_Points = circle_Points.map { |p| p + @first_point.position.to_a }
          Envelop::GeometryUtils.draw_lines(view, main_color, *circle_Points, circle_Points[0])

          # snapping lines
          draw_snap_lines(view, 16, 0.1, main_color)
          draw_snap_lines(view, 4, 0.25, nil)

        end

        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      IS_WIN = Sketchup.platform == :platform_win

      # This will ensure text is drawn with consistent size across platforms,
      # using pixels as size units.
      def draw_text(view, position, text, **options)
        native_options = options.dup
        if IS_WIN && options.key?(:size)
          native_options[:size] = pixels_to_points(options[:size])
        end
        view.draw_text(position, text, **native_options)
      end

      def pixels_to_points(pixels)
        ((pixels.to_f / 96.0) * 72.0).round
      end

      def draw_snap_lines(view, count, length, color)
        size = compute_north(@first_point, @mouse_ip).length.to_f
        snap_line = [[1, 0], [1 - length, 0]]
        count.times.each do |i|
          angle = (i * Math::PI * 2) / count
          rotated = snap_line.map do |p|
            sin = Math.sin(angle)
            cos = Math.cos(angle)
            Geom::Point3d.new((p[0] * cos + p[1] * -sin) * size, (p[0] * sin + p[1] * cos) * size, 0)

          end
          translated = rotated.map { |p| p + @first_point.position.to_a }

          Envelop::GeometryUtils.draw_lines(view, color, *translated)
        end
      end

      def getExtents
        if @first_point.valid?
          bb = Geom::BoundingBox.new
          north = compute_north(@first_point, @mouse_ip)
          east = Geom::Vector3d.new(north.y, -north.x, 0)
          center = @first_point.position
          bb.add(center + north + east, center + north - east, center - north + east, center - north - east)
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
            northAngle = Math.atan2(north.y, north.x)
            puts "north: #{north}, #{northAngle}"

            Envelop::OperationUtils.operation_chain "Set Orientation", true, lambda {
              Sketchup.active_model.set_attribute('Envelop::OrientationTool', 'northAngle', northAngle)
              Sketchup.active_model.set_attribute('Envelop::OrientationTool', 'modelIsOriented', true)
            }

            reset_tool
            view.invalidate

            Sketchup.active_model.select_tool(nil)
            @complete_callback.call unless @complete_callback.nil?
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
          ARROW.map do |p|
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

    #
    # Activate the orientation tool. The optional block gets executed if the tool completed successfully
    #
    def self.activate_orientation_tool(&complete_callback)
      Sketchup.active_model.select_tool(Envelop::OrientationTool::OrientationTool.new(&complete_callback))
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)

      if !is_model_oriented
        Envelop::OperationUtils.operation_chain "Set Orientation", true, lambda {
          Sketchup.active_model.set_attribute('Envelop::OrientationTool', 'northAngle', Math::PI / 2.0)
          Sketchup.active_model.set_attribute('Envelop::OrientationTool', 'modelIsOriented', true)
        }
      end
    end
    reload
  end
end
