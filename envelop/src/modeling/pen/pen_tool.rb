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

      def onCancel(reason, view)
        if @phase == PHASES[:MULTIPLE_POINTS]
          finish_with_points(@prev_points)
        else
          erase_construction_geometry
        end

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
        if @phase != PHASES[:INITIAL]
          super(flags, x, y, view, @prev_points[-1])
        else
          super(flags, x, y, view)
        end

        @target_faces = if @phase != PHASES[:INITIAL]
                          @prev_target_faces & pick_all_faces_set(view, x, y)
                        else
                          pick_all_faces_set(view, x, y)
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

            add_construction_geometry(@prev_points[-1], @ip.position)
            update_prev_state(@ip.position)
            @phase = PHASES[:MULTIPLE_POINTS]

          elsif @phase == PHASES[:MULTIPLE_POINTS]

            if @prev_points.include? @ip.position
              finish_with_point(@ip.position)
            end

            add_construction_geometry(@prev_points[-1], @ip.position)
            update_prev_state(@ip.position)
          end

          redraw
        end
      end

      def onReturn(_view)
        if @ip.valid?
          if @phase == PHASES[:INITIAL]
            add_construction_geometry(nil, @ip.position)
            update_prev_state(@ip.position)
            @phase = PHASES[:FIRST_POINT]

          elsif @phase == PHASES[:FIRST_POINT]
            return if try_finish_rectangle

            finish_with_point(@ip.position)

          elsif @phase == PHASES[:MULTIPLE_POINTS]

            finish_with_point(@ip.position) if @prev_points.length == 2

            finish_with_point(@prev_points[0])
          end
        end
      end

      def onUserDistances(distances) # TODO: test this
        if @phase == PHASES[:FIRST_POINT] && !@alternate_mode && distances.length >= 2
          ps = try_get_rectangle_points
          unless ps.nil?

            # calculate new points based on input
            v1 = ps[1] - ps[0]
            v2 = ps[2] - ps[1]
            v1.length = distances[0]
            v2.length = distances[1]

            ps = [ps[0], ps[0] + v1, ps[0] + v1 + v2, ps[0] + v2, ps[0]]

            finish_with_points(ps)
            return
          end
        end

        if @phase != PHASES[:INITIAL]

          v = @ip.position - @prev_points[-1]
          v.length = distances[0]
          p = @prev_points[-1] + v

          finish_with_point(p)
        end
      end

      def set_status_text # TODO: update this$
        if @phase == PHASES[:INITIAL]
          Sketchup.status_text = 'Click/`Enter` to select start point.'
          Sketchup.vcb_value = ''

        elsif @phase == PHASES[:FIRST_POINT]
          Sketchup.status_text = 'Click to select next point or confirm rectangle. Input manual distance to finish to the right. `Enter` to finish with next point or confirm rectangle. `Alt` to disable rectangle mode. `Esc` to abort.'
          Sketchup.vcb_value = try_get_triangle_distances || get_distance

        else
          if (@prev_points.length == 2)
            enterText = '`Enter` to finish with next point.'
          else
            enterText = '`Enter` to complete polygon with first point.'
          end

          Sketchup.status_text = 'Click to select next point, on previous point to finish. Input manual distance to finish to the right. ' + enterText + ' `Esc` to confirm previously selected points.'
          Sketchup.vcb_value = get_distance
        end
      end

      private

      # inherited

      def reset_tool
        @prev_points = []
        @construction_entities = []

        @target_faces = Set.new
        @prev_target_faces = Set.new

        super
      end

      def populateExtents(boundingBox)
        boundingBox.add(@ip) if @ip.valid?
        @prev_points.each { |p|; boundingBox.add(p) }
      end

      # internal

      def try_get_triangle_distances
        if not @alternate_mode
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
        if @ip.valid?
          distance = @ip.position.distance(@prev_points[-1])
        else
          distance = 0
        end
        distance.to_l.to_s
      end

      #
      # remove all construction lines and points
      #
      def erase_construction_geometry
        unless @construction_entities.empty?
          Envelop::OperationUtils.operation_chain('Pen Tool cleanup', true, lambda {
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
          Envelop::GeometryUtils.draw_lines(view, nil, @prev_points[-1], @ip.position)
        end
      end

      def finish_with_points(ps)
        # clear construction geometry before creating actual lines to get a clean undo history
        erase_construction_geometry

        # try to add edges to picked face without destroying the manifoldness of the faces parent
        face = try_get_target_face

        if (!face.nil?) && Envelop::OperationUtils.operation_chain('Pen Tool on Face', false, lambda {
                                                                                               # remember if the parent of the picked face is manifold
                                                                                               manifold_before = !face.parent.nil? && face.parent.manifold?

                                                                                               entities = (face.parent&.definition || Sketchup.active_model).entities

                                                                                               Envelop::GeometryUtils.create_line(entities, face.transform.inverse, ps, add_all_faces: false)

                                                                                               # check if the parent of the picked face is still manifold if it was before
                                                                                               !manifold_before || face.parent.manifold?
                                                                                             })
          # ok

        # either there was no face or the atempt with the picked face failed
        else
          Envelop::OperationUtils.operation_chain('Pen Tool', false, lambda {
            Envelop::GeometryUtils.create_line(Sketchup.active_model.entities, IDENTITY, ps, add_all_faces: true)
            true
          })
        end

        reset_tool
        redraw
      end

      def finish_with_point(point)
        @prev_points << point
        finish_with_points(@prev_points)
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
        @prev_points << point
        @prev_target_faces = @target_faces
      end

      def add_construction_geometry(last_point, new_point)
        Envelop::OperationUtils.operation_chain('Guide', true, lambda {
          # TODO: check if construction points/lines are necessary for inference, if so fix undo-stack littering
          @construction_entities << Sketchup.active_model.entities.add_cpoint(new_point)

          unless last_point.nil?
            @construction_entities << Sketchup.active_model.entities.add_cline(last_point, new_point)
          end
          true
        })
      end

      def try_get_rectangle_points
        normal = try_get_target_faces_normal
        Envelop::GeometryUtils.construct_rectangle(@prev_points[-1], @ip.position, normal)
      end

      def try_get_target_face
        @target_faces.length == 1 ? @target_faces.first : nil
      end

      def try_get_target_faces_normal
        face = try_get_target_face
        face ? Envelop::GeometryUtils.normal_transformation(face.transform) * face.entity.normal : nil
      end

      # @return [Set<PickResult>] a set with all faces, their transform and parent at x, y position
      def pick_all_faces_set(view, x, y)
        Set.new Envelop::GeometryUtils.pick_all_entity(view, x, y, Sketchup::Face)
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
