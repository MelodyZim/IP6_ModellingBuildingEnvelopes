# frozen_string_literal: true

module Envelop
  module PenTool
    class PenTool
      PHASES = { BEFORE_FIRST_POINT: 0, BEFORE_SECOND_POINT: 2, ADDITIONAL_POINTS: 3 }.freeze

      def initialize; end

      def activate
        puts 'activating PenTool...'
        reset_tool
      end

      def deactivate(view)
        puts 'deactivating PenTool...'

        # no need to reset_tool, tool instance will be discarded after this

        view.invalidate
      end

      def resume(view)
        # puts 'resuming PenTool...'

        set_status_text
        view.invalidate
      end

      def suspend(_view)
        # puts 'suspending PenTool...'
      end

      def onCancel(_reason, _view)
        Sketchup.active_model.select_tool(nil) # this will invalidate view & delete because phase will not be FINISHED
      end

      def draw(view)
        rectangle = false
        if @points.length == 1 and not @force_polygon
          if @mouse_ip.valid?
            p = get_points(@points[0], @mouse_ip)
            if p.length == 5; rectangle = true; end
          end
        else
          p = @points.map { |ip| ip.position }
          if @mouse_ip.valid?
            p << @mouse_ip.position
          end
        end
      
        if rectangle
          draw_lines(view, "Cyan", *p)
        elsif p.length >= 2
          draw_lines(view, nil, *p)
        end

        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      def getExtents
        bb = Geom::BoundingBox.new
        if @mouse_ip.valid?
          bb.add(@mouse_ip)
        end
        @points.each { |p|; bb.add(p.position) }
        return bb
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        UI.set_cursor(CURSOR_PENCIL)
      end

      def onMouseMove(_flags, x, y, view)
        if @points.length > 0
          @mouse_ip.pick(view, x, y, @points[-1])
        else
          @mouse_ip.pick(view, x, y)
        end
      
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onReturn(view)
        if @points.length >= 3
          @points << @points[0]
          num_new_faces = create_line(@entities, @transform, @points[-2].position, @points[-1].position)
          Envelop::Materialisation.apply_default_material
          reset_tool
        end
      end

      def onKeyDown(key, _repeat, _flags, view)
        if key == CONSTRAIN_MODIFIER_KEY
          # locks the inference based on @mouse_ip input point
          view.lock_inference(@mouse_ip)
        elsif key == VK_CONTROL or key == VK_ALT
          @force_polygon = true
        end

        view.invalidate
      end
      
      def onKeyUp(key, _repeat, _flags, view)
        if key == CONSTRAIN_MODIFIER_KEY
          # unlock inference
          view.lock_inference
        elsif key == VK_CONTROL or key == VK_ALT
          @force_polygon = false
        end

        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        if @mouse_ip.valid?
          # append mouse position to points array
          @points << Sketchup::InputPoint.new.copy!(@mouse_ip)
          
          if @entities.nil?
            parent = @mouse_ip.face&.parent
            if not parent.nil? and parent.is_a? Sketchup::ComponentDefinition and parent.group?
              @entities = parent.entities
            else
              @entities = Sketchup.active_model.active_entities
            end
            @transform = @points[0].transformation
          end
        
          if @points.length == 2 and not @force_polygon
            # # add new edges at top level if the first two points are not on the same face
            if get_common_face(@points[0], @points[1]).nil?
              @entities = Sketchup.active_model.active_entities
              @transform = Geom::Transformation.new
            end
          
            num_new_faces = create_line(@entities, @transform, *get_points(@points[0], @points[1]))
            Envelop::Materialisation.apply_default_material

            if num_new_faces > 0
              reset_tool
            end
          elsif @points.length >= 2
            num_new_faces = create_line(@entities, @transform, @points[-2].position, @points[-1].position)
            Envelop::Materialisation.apply_default_material
            if num_new_faces > 0
              reset_tool
            end
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
      
      
      # Create Sketchup::Edges as children of the specified Sketchup::Entities that form a line
      #
      # @param entities [Sketchup::Entities] the entities that will contain the added edges
      # @param transform [Sketchup::Transformation] the transformation to apply to the points
      # @param points [Sketchup::Point3d] the points of a continuous line
      #
      # @return [Numeric] the number of faces created
      def create_line(entities, transform, *points)
        num_faces = 0
        model = Sketchup.active_model
        transform = transform.inverse
        points = points.map {|p| transform * p }
        model.start_operation('Edge', true)
        points[0..-2].zip(points[1..-1]).each do |line| 
          edge = entities.add_line(line[0], line[1])
          num_faces += edge.find_faces
        end
        model.commit_operation
        return num_faces
      end


      # Get a face that both input points have in common
      #
      # @param ip1 [Sketchup::InputPoint] first input point
      # @param ip2 [Sketchup::InputPoint] second InputPoint
      #
      # @return [Sketchup::Face, nil]
      def get_common_face(ip1, ip2)
        face = nil
        if ip1.edge.nil?
          if ip2.edge.nil?
            if ip1.face == ip2.face
              face = ip1.face
            end
          else
            if ip2.edge.used_by?(ip1.face)
              face = ip1.face
            end
          end
        else
          if ip2.edge.nil?
            if ip1.edge.used_by?(ip2.face)
              face = ip2.face
            end
          else
            face = ip1.edge.common_face(ip2.edge)
          end
        end
        return face
      end

      
      # Given two InputPoint return a list of points:
      # If ip1 and ip2 form a line parallel to an axis the positions of ip1 and ip2 are returned
      # otherwise ip1 and ip2 form the opposite corners of a rectangle.
      # When ip1 and ip2 share a Sketchup::Face then the rectangle is lies on that face
      # otherwise the rectangle is axis-aligned
      #
      # @param ip1 [Sketchup::InputPoint] the first InputPoint
      # @param ip2 [Sketchup::InputPoint] the second InputPoint
      #
      # @return [Array<Sketchup::Point3d>] the list of points resulting points
      def get_points(ip1, ip2)
        line = ip2.position - ip1.position
        
        # return if the points are at the same location
        if line.length == 0
          return Array.new
        end
        
        x_axis = Geom::Vector3d.new(1,0,0)
        y_axis = Geom::Vector3d.new(0,1,0)
        z_axis = Geom::Vector3d.new(0,0,1)
        
        # try to get a common face from the input points
        face = get_common_face(ip1, ip2)
        
        if face.nil? or z_axis.cross(face.normal).length == 0
        
          # check if ip1 and ip2 form a line parallel to a basic axis
          if line.parallel?(x_axis) or line.parallel?(y_axis) or line.parallel?(z_axis)
            return [ip1.position, ip2.position]
          else
            # form a rectangle on the plane perpendicular to the axis with the smallest absolute difference
            abs_line = line.to_a.map {|e|; e.abs}
            closest_plane = abs_line.index(abs_line.min)
            a = ip1.position
            b = ip2.position
            
            case closest_plane
            when 0  # Y/Z
              return [
                a, 
                Geom::Point3d.new(a.x,a.y,b.z), 
                Geom::Point3d.new(a.x,b.y,b.z), 
                Geom::Point3d.new(a.x,b.y,a.z), 
                a]
            when 1  # X/Z
              return [
                a, 
                Geom::Point3d.new(b.x,a.y,a.z), 
                Geom::Point3d.new(b.x,a.y,b.z), 
                Geom::Point3d.new(a.x,a.y,b.z), 
                a]
            when 2  # X/Y
              return [
                a, 
                Geom::Point3d.new(a.x,b.y,a.z), 
                Geom::Point3d.new(b.x,b.y,a.z), 
                Geom::Point3d.new(b.x,a.y,a.z), 
                a]
            end
          end
        else
          # axes on the face (perpendicular to the face normal)
          right_axis = z_axis.cross(face.normal)
          up_axis = right_axis.cross(face.normal)
          
          # check if the line is parallel to a face axis
          if line.parallel?(right_axis) or line.parallel?(up_axis)
            return [ip1.position, ip2.position]
          else
            # decompose line vector into v_up and v_right
            # right_axis.z is always zero
            
            s = (line.z / up_axis.z)
            v_up = Geom::Vector3d.new(up_axis.to_a.map{|c| c * s})
            v_right = line - v_up
            
            a = ip1.position
            b = ip2.position
            
            return [a, a + v_up, b, a + v_right, a]
            
          end
        end
      end
      
      def reset_tool
        # reset state
        @phase = PHASES[:BEFORE_FIRST_POINT]
        @mouse_ip = Sketchup::InputPoint.new
        @points = Array.new
        @force_polygon = false
        
        @entities = nil
        @transform = Geom::Transformation.new

        set_status_text
      end
    end

    def self.activate_pen_tool
      Sketchup.active_model.select_tool(Envelop::PenTool::PenTool.new)
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
