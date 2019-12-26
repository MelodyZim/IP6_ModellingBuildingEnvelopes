# frozen_string_literal: true

module Envelop
  module PushPullTool
    class PushPullTool   

      # @param add [Boolean] whether the created volume should be added (true) or subtracted (false) from the house
      def initialize(add = true)
        @add = add
      end

      def activate
        puts 'activating PushPullTool...'
        reset_tool
      end

      def deactivate(view)
        puts 'deactivating PushPullTool...'

        # no need to reset_tool, tool instance will be discarded after this

        # release inference locks
        view.lock_inference

        view.invalidate
      end

      def resume(view)
        # puts 'resuming PushPullTool...'

        set_status_text
        view.invalidate
      end

      def suspend(_view)
        # puts 'suspending PushPullTool...'
      end

      def onCancel(_reason, _view)
        Sketchup.active_model.select_tool(nil) # this will invalidate view & delete because phase will not be FINISHED
      end

      def draw(view)
        if not @face.nil?
          points = @face.vertices.map {|v| v.position + @direction_vector}
          points << points[0]
          draw_lines(view, "Cyan", *points)
        end
      end

      def getExtents
        bb = Geom::BoundingBox.new
        if not @face.nil?
          bb.add(@face.vertices)
          bb.add(@face.vertices.map {|v| v.position + @direction_vector})
        end
        return bb
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        UI.set_cursor(CURSOR_PENCIL)
      end

      def onMouseMove(_flags, x, y, view)
        @mouse_ip.pick(view, x, y)
        
        if not @face.nil?        
          n = @face.normal
          v = @mouse_ip.position - @face.vertices[0].position

          s = (v.dot(n) / (n.length ** 2))
          @direction_vector = Geom::Vector3d.new(n.to_a.map{|c| c * s})
        end
      
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        if @mouse_ip.valid?
          if @face.nil?
            @face = @mouse_ip.face
            unless @face.nil?
              @transform = @mouse_ip.transformation
              view.lock_inference(
                Sketchup::InputPoint.new(@face.vertices[0]), 
                Sketchup::InputPoint.new(@face.vertices[0].position + @face.normal))
            end
          else
            # TODO cleanup code
            points = @face.vertices.map {|v| v.position}
            sign = @direction_vector.samedirection?(@face.normal) ? 1 : -1
          
            model = Sketchup.active_model
            group = model.active_entities.add_group()
            group.transformation = @transform
            face_copy = group.entities.add_face(points)
            
            face_copy.pushpull(sign * @direction_vector.length, false)
            
            # Add newly created group to house
            if @add
              Envelop::Housekeeper.add_to_house(group)
            else
              Envelop::Housekeeper.remove_from_house(group)
            end
            
            Envelop::Materialisation.apply_default_material
            
            # delete original face
            if not @face.deleted?
              edges = @face.edges
              @face.erase!
              edges.each do |e|
                if e.faces.length == 0
                  e.erase!
                end
              end
            end
            
            # release inference locks
            view.lock_inference
            
            reset_tool
          end
        end
      end

      def set_status_text
        Sketchup.status_text = 'TODO UPDATE set_status_text!!!!'
      end
      
      # Draw the given points as a continuous line
      # if color is nil the default Sketchup axis colors are used
      #
      # @param view [Sketchup::View]
      # @param color [Sketchup::Color, String, nil]
      # @param points [Array<Sketchup::Point3d>]
      def draw_lines(view, color, *points)
        if color.nil?
          for i in 1..points.length-1 do
            view.set_color_from_line(points[i - 1], points[i])
            view.draw_line(points[i - 1], points[i])
          end
        else
          view.drawing_color= color
          view.draw_polyline points
        end
      end
      
      def reset_tool
        # reset state
        @mouse_ip = Sketchup::InputPoint.new
        @face = nil
        @direction_vector = Geom::Vector3d.new
        @transform = Geom::Transformation.new

        set_status_text
      end
    end

    # Activate the custom Push-Pull Tool
    #
    # @param add [Boolean] whether the created volume should be added (true) or subtracted (false) from the house
    #
    def self.activate_pushpull_tool(add=true)
      Sketchup.active_model.select_tool(Envelop::PushPullTool::PushPullTool.new(add))
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
