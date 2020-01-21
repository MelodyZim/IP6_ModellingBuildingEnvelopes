# frozen_string_literal: true

module Envelop
  module PenTool
    class PenTool
      def initialize; end

      def activate
        puts 'activating PenTool...'
        reset_tool
      end

      def deactivate(view)
        puts 'deactivating PenTool...'

        # reset tool to clean up left over construction entities
        reset_tool

        # release inference locks
        view.lock_inference

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

      def onCancel(reason, _view)
        finish_operation(@points) if @points.length >= 2
        reset_tool
      end

      def draw(view)
        rectangle_drawn = false
        if (@points.length == 1) && !@force_polygon
          # draw rectangle preview
          if @mouse_ip.valid?
            pick_face = @pick_faces_preview.length == 1 ? @pick_faces_preview.to_a[0] : false
            face_normal = pick_face ? Envelop::GeometryUtils.normal_transformation(pick_face.transform) * pick_face.entity.normal : nil
            p = construct_rectangle(@points[0], @mouse_ip.position, face_normal)
            if p
              Envelop::GeometryUtils.draw_lines(view, 'Cyan', *p, p[0])
              rectangle_drawn = true
            end
          end
        end

        if @points.length >= 1 && !rectangle_drawn
          # draw line preview
          Envelop::GeometryUtils.draw_lines(view, nil, *@points, @mouse_ip.position)
        end

        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      def getExtents
        bb = Geom::BoundingBox.new
        bb.add(@mouse_ip) if @mouse_ip.valid?
        @points.each { |p|; bb.add(p) }
        bb
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        UI.set_cursor(CURSOR_PENCIL)
      end

      def onMouseMove(_flags, x, y, view)
        if !@points.empty?
          @mouse_ip.pick(view, x, y, Sketchup::InputPoint.new(@points[-1]))
          @pick_faces_preview = @pick_faces & pick_all_faces(view, x, y)
        else
          @mouse_ip.pick(view, x, y)
          @pick_faces_preview = pick_all_faces(view, x, y)
        end

        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onReturn(_view)
        if @points.length >= 3
          # close shape
          @points << @points[0]

          finish_operation(@points)
        end
      end

      def onKeyDown(key, _repeat, _flags, view)
        if key == CONSTRAIN_MODIFIER_KEY
          # locks the inference based on @mouse_ip input point
          view.lock_inference(@mouse_ip)
        elsif (key == VK_CONTROL) || (key == VK_ALT)
          @force_polygon = true
        end

        view.invalidate
      end

      def onKeyUp(key, _repeat, _flags, view)
        if key == CONSTRAIN_MODIFIER_KEY
          # unlock inference
          view.lock_inference
        elsif (key == VK_CONTROL) || (key == VK_ALT)
          @force_polygon = false
        end

        view.invalidate
      end

      def onLButtonDown(_flags, _x, _y, _view)
        if @mouse_ip.valid?
          # append mouse position to points array
          @points << @mouse_ip.position
          @pick_faces = @pick_faces_preview

          # create construction point and edges
          Envelop::OperationUtils.operation_block 'Guide' do
            # TODO: check if construction points/lines are necessary for inference, if so fix undo-stack littering
            @construction_entities << Sketchup.active_model.entities.add_cpoint(@mouse_ip.position)
            if @points.length > 1
              @construction_entities << Sketchup.active_model.entities.add_cline(@points[-2], @points[-1])
            end
            true
          end

          if (@points.length == 2) && !@force_polygon
            # try to create a rectangle
            finish_operation do |face_normal|
              rectangle = construct_rectangle(@points[0], @points[1], face_normal)
              if rectangle
                # add the starting point to the end to close the shape
                rectangle << rectangle[0]
              end
              rectangle
            end
          elsif @points.length >= 2
            # TODO: find better finish condition
            # if last point is equal to one of the previous points, the shape is close and the tool finishes
            finish_operation(@points) if @points[0..-2].include? @points[-1]
          end
        end

        set_status_text
      end

      def set_status_text
        if @points.empty?
          Sketchup.status_text = 'Select start point'
        elsif @points.length == 1
          Sketchup.status_text = 'Select next point. Ctrl = toggle between rectangle and line'
        else
          Sketchup.status_text = 'Select next point'
        end
      end

      #
      # Create Sketchup::Edges as children of the specified Sketchup::Entities that form a line
      #
      # @param entities [Sketchup::Entities] the entities that will contain the added edges
      # @param transform [Geom::Transformation] the transformation to apply to the points
      # @param points [Array<Geom::Point3d>] Array of the points of a continuous line
      # @param add_all_faces [Boolean] whether all adjacent faces should be added, if false
      #   Sketchup::Edge.find_faces is only called for edges with no initial faces
      #
      # @return [Numeric] the number of faces created
      #
      def create_line(entities, transform, points, add_all_faces: true)
        points = points.map { |p| transform * p }
        edges_to_check = []
        points[0..-2].zip(points[1..-1]).each do |line|
          edge = entities.add_line(line[0], line[1])
          edges_to_check << edge if edge && (edge.faces.empty? || add_all_faces)
        end

        # add faces and return the total count of faces created
        edges_to_check.map(&:find_faces).sum
      end

      #
      # Construct a rectangle from two points. The input points are on the
      # diagonal of the resulting rectangle. One side of the rectangle is
      # always perpendicular to the Z-Axis. If p1 and p2 form a line parallel
      # to an axis then the result is nil.
      #
      # @param p1 [Geom::Point3d] the first Point
      # @param p2 [Geom::Point3d] the second Point
      # @param face_normal [Geom::Vector3d, nil] the normal of the plane in which
      #   the rectangle lies, if nil the closest plane X/Y, X/Z or Y/Z is used
      #
      # @return [Array<Geom::Point3d>, nil] an array of points of length 4
      #   that make up a rectangle or nil if no rectangle was found
      #
      def construct_rectangle(p1, p2, face_normal = nil)
        # determine the face_normal
        if face_normal.nil?
          # form the rectangle on the plane perpendicular to the axis with the smallest absolute difference
          abs_diagonal = (p2 - p1).to_a.map(&:abs)
          face_normal = [X_AXIS, Y_AXIS, Z_AXIS][abs_diagonal.index(abs_diagonal.min)]
        end

        # project the second point on the plane defined by the first point and the normal vector
        p2 = p2.project_to_plane([p1, face_normal])
        diagonal = p2 - p1

        # return if the points are at the same location
        return nil unless diagonal.valid?

        if Z_AXIS.cross(face_normal).valid?
          # axes on the face (perpendicular to the face normal)
          right_axis = Z_AXIS.cross(face_normal)
          up_axis = right_axis.cross(face_normal)

          # check if the diagonal is parallel to a face axis
          if diagonal.parallel?(right_axis) || diagonal.parallel?(up_axis)
            nil
          else
            # decompose diagonal vector into v_up and v_right
            # right_axis.z is always zero because it is perpendicular to Z_AXIS
            s = (diagonal.z / up_axis.z)
            v_up = Geom::Vector3d.new(up_axis.to_a.map { |c| c * s })
            v_right = diagonal - v_up

            [p1, p1 + v_right, p2, p1 + v_up]
          end
        else
          # check if p1 and p2 form a line parallel to a basic axis
          if diagonal.parallel?(X_AXIS) || diagonal.parallel?(Y_AXIS)
            nil
          else
            [
              p1,
              Geom::Point3d.new(p1.x, p2.y, p1.z),
              Geom::Point3d.new(p2.x, p2.y, p1.z),
              Geom::Point3d.new(p2.x, p1.y, p1.z)
            ]
          end
        end
      end

      PickResult = Struct.new(:entity, :transform, :parent) do
        def hash
          entity.hash
        end

        def eql?(other)
          entity.eql? other.entity
        end
      end

      # @return [Set<PickResult>] a set with all faces, their transform and parent at x, y position
      def pick_all_faces(view, x, y)
        ph = view.pick_helper(x, y, aperture = 20) # TODO: investigate what the best value for aperture is
        Set.new (0..ph.count - 1)
          .map { |i| PickResult.new(ph.leaf_at(i), ph.transformation_at(i), ph.path_at(i)[-2]) }
          .select { |p| p.entity.is_a? Sketchup::Face }
          .select { |p| p.parent.nil? || !p.parent.is_a?(Sketchup::Image) }
      end

      #
      # Finish the pen tool operation
      #
      # @param points [Array<Geom::Point3d>, nil] points that make up the line
      #
      # @yield [face_normal] the normal of the face where the points are on or nil
      #
      # @yieldreturn [Array<Geom::Point3d>, nil] an array of points that define a continuous line or nil to abort
      #
      # @return [Boolean] whether the operation was successfully finished
      #
      def finish_operation(points = nil)
        # check if there is an appropriate face to put all edges on
        pick_face = @pick_faces.length == 1 ? @pick_faces.to_a[0] : false
        face_normal = pick_face ? Envelop::GeometryUtils.normal_transformation(pick_face.transform) * pick_face.entity.normal : nil

        # get the points
        points = yield face_normal if block_given?

        if points
          # try to add edges to picked face without destroying the manifoldness of the faces parent
          if pick_face
            pick_face = Envelop::OperationUtils.operation_block('Pen Tool on Face') do
              # remember if the parent of the picked face is manifold
              manifold_before = !pick_face.parent.nil? && pick_face.parent.manifold?

              entities = (pick_face.parent&.definition || Sketchup.active_model).entities
              create_line(entities, pick_face.transform.inverse, points, add_all_faces: false)

              # check if the parent of the picked face is still manifold if it was before
              !manifold_before || pick_face.parent.manifold?
            end
          end

          # either there was no face or the atempt with the picked face failed
          unless pick_face
            Envelop::OperationUtils.operation_block('Pen Tool') do
              create_line(Sketchup.active_model.entities, IDENTITY, points, add_all_faces: true)
              true
            end
          end

          reset_tool
          true
        else
          false
        end
      end

      def reset_tool
        # remove all construction lines and points
        Envelop::OperationUtils.operation_block 'Pen Tool cleanup' do
          @construction_entities&.each(&:erase!)
          true
        end

        # reset state
        @mouse_ip = Sketchup::InputPoint.new
        @points = []
        @construction_entities = []
        @force_polygon = false

        @pick_faces = Set.new
        @pick_faces_preview = Set.new

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
