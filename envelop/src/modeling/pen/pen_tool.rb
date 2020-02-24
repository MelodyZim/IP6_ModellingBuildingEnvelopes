# frozen_string_literal: true

module Envelop
  module PenTool
    class PenTool < Envelop::ToolUtils::AbstractTool
      PHASES = { INITIAL: 0, FIRST_POINT: 1, MULTIPLE_POINTS: 2 }.freeze

      def initialize
        super(PenTool, phases: PHASES, cursor_id: Envelop::ToolUtils::CURSOR_PENCIL)
      end

      def deactivate(view)
        super(view)

        erase_construction_geometry
      end

      # TODO also end on dragged in mouse up

      def onCancel(reason, view)
        erase_construction_geometry

        super(reason, view)
      end

      def enableVCB?
        @phase != PHASES[:INITIAL]
      end

      def draw(view)
        super(view)

        draw_preview(view) if @phase != PHASES[:INITIAL] && @ip.valid?
      end

      def onMouseMove(flags, x, y, view)
        if @phase == PHASES[:INITIAL]
          super(flags, x, y, view)
        else
          super(flags, x, y, view, @previous_points[-1])
        end

        @target_normals = if @phase == PHASES[:INITIAL]
                            pick_all_faces_normals_set(view, x, y)
                          else
                            @previous_target_normals & pick_all_faces_normals_set(view, x, y)
                          end
      end

      def onLButtonDown(flags, x, y, view)
        super(flags, x, y, view)

        if @ip.valid?

          if @phase == PHASES[:INITIAL]
            add_construction_geometry(nil, @ip.position)
            update_prev_state(@ip.position)
            @phase = PHASES[:FIRST_POINT]

          elsif @phase == PHASES[:FIRST_POINT]

            return if try_finish_rectangle
            if on_edge_or_vertex(view, x, y)
              finish_with_additional_point(@ip.position)
            else
              add_construction_geometry(@previous_points[-1], @ip.position)
              update_prev_state(@ip.position)
              @phase = PHASES[:MULTIPLE_POINTS]
            end

          elsif @phase == PHASES[:MULTIPLE_POINTS]
            
            if (@previous_points.include? @ip.position) || on_edge_or_vertex(view, x, y)
              finish_with_additional_point(@ip.position)
            else
              add_construction_geometry(@previous_points[-1], @ip.position)
              update_prev_state(@ip.position)
            end

          end

          redraw
        end
      end

      def onReturn(_view)
        if @ip.valid?
          if @phase == PHASES[:FIRST_POINT]
            return if try_finish_rectangle
          elsif @phase == PHASES[:MULTIPLE_POINTS]
            if @alternate_mode
              # close the shape
              finish_with_additional_point(@previous_points[0])
            else
              # finish with existing points
              finish_with_points(@previous_points)
            end
          end
        end
      end

      def onKeyDown(key, repeat, flags, view)
        super(key, repeat, flags, view)
        if key == Envelop::ToolUtils::KEY_ENTER
          onReturn(view)
        end
      end

      def set_status_text # TODO: update this$
        if @phase == PHASES[:INITIAL]
          Sketchup.status_text = 'Click/`Enter` to select start point.'
          Sketchup.vcb_value = ''

        elsif @phase == PHASES[:FIRST_POINT]
          Sketchup.status_text = 'Click to select next point or confirm rectangle. Input manual distance to finish in the textfield. `Enter` to finish with next point or confirm rectangle. `Alt` to disable rectangle mode. `Esc` to abort.'
          Sketchup.vcb_value = try_get_rectangle_distances || get_distance

        else
          enterText = if @previous_points.length == 2
                        '`Enter` to finish with next point.'
                      else
                        '`Enter` to complete polygon with first point.'
                      end

          Sketchup.status_text = 'Click to select next point, on previous point to finish. Input manual distance to finish in the textfield. ' + enterText + ' `Esc` to confirm previously selected points.'
          Sketchup.vcb_value = get_distance
        end
      end

      private

      # inherited

      def reset_tool
        @previous_points = []
        @construction_entities = []

        @target_normals = Set.new
        @previous_target_normals = Set.new

        super
      end

      def populateExtents(boundingBox)
        boundingBox.add(@ip) if @ip.valid?
        @previous_points.each { |p|; boundingBox.add(p) }
      end

      def onUserDistances(distances)
        if @phase == PHASES[:FIRST_POINT] && !@alternate_mode
          ps = try_get_rectangle_points
          unless ps.nil?

            # calculate new points based on input
            v1 = ps[1] - ps[0]
            v2 = ps[2] - ps[1]
            v1.length = distances[0] unless distances[0].nil?
            v2.length = distances[1] unless distances[1].nil?

            ps = [ps[0], ps[0] + v1, ps[0] + v1 + v2, ps[0] + v2, ps[0]]

            @target_normals = @previous_target_normals
            finish_with_points(ps)
            return
          end
        end

        if @phase != PHASES[:INITIAL]

          v = @ip.position - @previous_points[-1]
          v.length = distances[0]
          p = @previous_points[-1] + v

          @target_normals = @previous_target_normals
          finish_with_additional_point(p)
        end
      end

      # internal

      def try_get_rectangle_distances
        unless @alternate_mode
          ps = try_get_rectangle_points
          unless ps.nil?
            v1 = ps[1] - ps[0]
            v2 = ps[2] - ps[1]
            return "#{v1.length.to_l}, #{v2.length.to_l}"
          end
        end

        nil
      end

      def get_distance
        distance = if @ip.valid?
                     @ip.position.distance(@previous_points[-1])
                   else
                     0
                   end
        distance.to_l.to_s
      end

      #
      # remove all construction lines and points
      #
      def erase_construction_geometry
        unless @construction_entities.empty?
          Envelop::OperationUtils.operation_chain('Internal Preview Operation', true, lambda {
            @construction_entities&.each(&:erase!)
            @construction_entities = []
            true
          })
        end
      end

      def draw_preview(view)
        if @phase == PHASES[:FIRST_POINT] && !@alternate_mode
          ps = try_get_rectangle_points
          unless ps.nil?
            Envelop::GeometryUtils.draw_lines(view, 'Cyan', *ps, ps[0])
            return
          end
        end

        if @phase != PHASES[:INITIAL]
          Envelop::GeometryUtils.draw_lines(view, nil, @previous_points[-1], @ip.position)
        end
      end

      def finish_with_points(ps)
        # clear construction geometry before creating actual lines to get a clean undo history
        erase_construction_geometry

        # try to add edges to the house
        house = Envelop::Housekeeper.get_or_find_house
        successful = Envelop::OperationUtils.operation_chain('Pen Tool', false, lambda {
          !house.nil?
        }, lambda {
          Envelop::GeometryUtils.create_line(house.entities, house.transformation.inverse, ps, add_all_faces: false)

          # check if house is stil manifold
          Envelop::Housekeeper.get_or_find_house&.manifold? || false
        })

        #  if the previous attempt failed add the lines to active_entities
        unless successful
          Envelop::OperationUtils.operation_chain('Pen Tool', false, lambda {
            Envelop::GeometryUtils.create_line(Sketchup.active_model.active_entities, IDENTITY, ps, add_all_faces: true)
            true
          })
        end

        reset_tool
        redraw
      end

      def finish_with_additional_point(point)
        @previous_points << point
        finish_with_points(@previous_points)
      end

      def try_finish_rectangle
        unless @alternate_mode
          ps = try_get_rectangle_points # could use result from previw if performance becomes an issue

          unless ps.nil?
            ps << ps[0]
            finish_with_points(ps)
            return true
          end
        end

        false
      end

      def update_prev_state(point)
        @previous_points << point
        @previous_target_normals = @target_normals
      end

      def add_construction_geometry(last_point, new_point)
        Envelop::OperationUtils.operation_chain('Internal Preview Operation', true, lambda {
          # TODO: check if construction points/lines are necessary for inference, if so fix undo-stack littering
          @construction_entities << Sketchup.active_model.entities.add_cpoint(new_point)

          unless last_point.nil?
            @construction_entities << Sketchup.active_model.entities.add_cline(last_point, new_point)
          end
          true
        })
      end

      # check if the x, y position points on an edge or vertex
      def on_edge_or_vertex(view, x, y)
        !(Envelop::GeometryUtils.pick_all_entity(view, x, y).select do
          |p| (p.entity.is_a? Sketchup::Edge) || (p.entity.is_a? Sketchup::Vertex)
        end).empty?
      end

      def try_get_rectangle_points
        normal = try_get_target_face_normal
        Envelop::GeometryUtils.construct_rectangle(@previous_points[-1], @ip.position, normal)
      end

      # try to get the normal of the face we are on
      def try_get_target_face_normal
        @target_normals.length == 1 ? @target_normals.first.vector3d : nil
      end

      # @return [Set<PickResult>] a set with all faces, their transform and parent at x, y position
      def pick_all_faces_normals_set(view, x, y)
        Set.new Envelop::GeometryUtils.pick_all_entity(view, x, y, Sketchup::Face).map { |f| ComparableVector3d.new(f.entity.normal) }
      end

      # Wrapper for using Geom::Vector3d inside a ruby sets
      ComparableVector3d = Struct.new(:vector3d) do
        def hash
          round(vector3d).hash
        end

        def eql?(other)
          round(vector3d).eql? round(other.vector3d)
        end

        def round(vector3d)
          vector3d.to_a.map { |e| e.round(5) }
        end
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
