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
        Sketchup.active_model.select_tool(nil)
      end

      def draw(view)
        unless @face.nil?
          color = @pushpull_vector.valid? && @pushpull_vector.samedirection?(@direction) ? 'Cyan' : 'Magenta'

          # draw new face
          @face.loops.each do |loop|
            points = loop.vertices.map { |v| @transform * v.position + @pushpull_vector }
            points << points[0]
            Envelop::GeometryUtils.draw_lines(view, color, *points)
          end

          # draw connections to old face
          @face.outer_loop.vertices.each do |v|
            Envelop::GeometryUtils.draw_lines(view, color, @transform * v.position, @transform * v.position + @pushpull_vector)
          end

          # draw InputPoint if appropriate
          if @mouse_ip.display? && (@mouse_ip.edge || @mouse_ip.vertex)
            @mouse_ip.draw(view)
            view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
          end
        end
      end

      def getExtents
        bb = Geom::BoundingBox.new
        unless @face.nil?
          bb.add(@face.vertices)
          bb.add(@face.vertices.map { |v| @transform * v.position + @pushpull_vector })
        end
        bb
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        UI.set_cursor(CURSOR_PENCIL)
      end

      def onMouseMove(_flags, x, y, view)
        @mouse_ip.pick(view, x, y)

        unless @face.nil?
          line = [@origin, @direction]
          if @mouse_ip.edge.nil? && @mouse_ip.vertex.nil?
            camera_ray = view.pickray(x, y)
            target = Geom.closest_points(line, camera_ray)[0]
          else
            target = @mouse_ip.position.project_to_line(line)
          end

          @pushpull_vector = target - @origin
        end

        view.invalidate
      end

      def onLButtonDown(_flags, x, y, view)
        if @face.nil?
          @face, @transform = Envelop::GeometryUtils.pick_entity(view, x, y, Sketchup::Face)

          unless @face.nil?
            @origin = @transform * @face.bounds.center
            @direction = Envelop::GeometryUtils.normal_transformation(@transform) * @face.normal
          end
        else
          Envelop::OperationUtils.operation_chain "Push/Pull #{@add ? 'Add' : 'Subtract'}", lambda {
            @pushpull_vector.valid?
          }, lambda  {
            group = Envelop::GeometryUtils.pushpull_face(@face, transform: @transform) { |p| p + @pushpull_vector }

            # Add newly created group to house
            if @add
              Envelop::Housekeeper.add_to_house(group)
            else
              Envelop::Housekeeper.remove_from_house(group)
            end
          }, lambda  {
            Envelop::Materialisation.apply_default_material

            # delete original face
            Envelop::GeometryUtils.erase_face(@face) unless @face.deleted?

            # return true to commit operation
            true
          }

          reset_tool
        end

        set_status_text
      end

      def onLButtonDoubleClick(_flags, x, y, view)
        puts 'Envelop::PushPullTool.onLButtonDoubleClick called'

        face, transform = Envelop::GeometryUtils.pick_entity(view, x, y, Sketchup::Face)
        unless face.nil?
          # extrude the face to create a flat plateau in the x/y plane

          face_normal = Envelop::GeometryUtils.normal_transformation(transform) * face.normal
          z_coords = face.vertices.map { |v| (transform * v.position).z }
          max_z = z_coords.max
          min_z = z_coords.min

          Envelop::OperationUtils.operation_chain 'Lukarne', lambda {
            # only continue if face is sloped
            !face_normal.parallel?(Z_AXIS) && !face_normal.perpendicular?(Z_AXIS)
          }, lambda  {
            group = Envelop::GeometryUtils.pushpull_face(face, transform: transform) do |p|
              Geom::Point3d.new(p.x, p.y, face_normal.dot(Z_AXIS) > 0 ? max_z : min_z)
            end

            # add the group to the house
            Envelop::Housekeeper.add_to_house(group)
          }, lambda  {
            Envelop::Materialisation.apply_default_material
            true
          }
        end

        reset_tool
      end

      def set_status_text
        if @face.nil?
          Sketchup.status_text = 'Select a Face to push or pull. Double click a sloped Face to create a dormer'
        else
          Sketchup.status_text = 'Click to accept preview'
        end
      end

      def reset_tool
        # reset state
        @mouse_ip = Sketchup::InputPoint.new

        @face = nil
        @transform = nil
        @origin = nil
        @direction = nil

        @pushpull_vector = Geom::Vector3d.new

        set_status_text
      end
    end

    #
    # Activate the custom Push-Pull Tool
    #
    # @param add [Boolean] whether the created volume should be added (true) or subtracted (false) from the house
    #
    def self.activate_pushpull_tool(add = true)
      Sketchup.active_model.select_tool(Envelop::PushPullTool::PushPullTool.new(add))
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
