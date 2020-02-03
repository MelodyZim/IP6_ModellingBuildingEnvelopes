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

        # clean up left over construction entities
        erase_construction_geometry

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

      def onCancel(_reason, _view)
        if @points.length >= 2
          finish_operation(@points)
        else
          erase_construction_geometry
        end
        reset_tool
      end

      def enableVCB?
        !@points.empty?
      end

      def draw(view)
        rectangle_drawn = false
        if (@points.length == 1) && !@force_polygon
          # draw rectangle preview
          if @mouse_ip.valid?
            p = Envelop::GeometryUtils.construct_rectangle(@points[0], @mouse_ip.position, get_face_normal_preview)
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
        set_status_text
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
          set_status_text
        end

        view.invalidate
      end

      def onKeyUp(key, _repeat, _flags, view)
        if key == CONSTRAIN_MODIFIER_KEY
          # unlock inference
          view.lock_inference
        elsif (key == VK_CONTROL) || (key == VK_ALT)
          @force_polygon = false
          set_status_text
        end

        view.invalidate
      end

      def onUserText(text, _view)
        # TODO: reduce code duplication (similarities to onLButtonDown, set_status_text)
        if @mouse_ip.valid?
          rectangle = false

          if @points.length == 1 && !@force_polygon
            # get rectangle points
            p = Envelop::GeometryUtils.construct_rectangle(@points[0], @mouse_ip.position, get_face_normal_preview)

            unless p.nil?
              rectangle = true

              # expect up to two values
              input_list = text.split(/\s*[; ]\s*/).map { |s| s.empty? ? nil : s.to_l.to_f }

              # calculate new points based on input
              v1 = p[1] - p[0]
              v2 = p[2] - p[1]
              v1.length = input_list[0] unless input_list[0].nil?
              v2.length = input_list[1] unless input_list[0].nil?

              p_new = [p[0], p[0] + v1, p[0] + v1 + v2, p[0] + v2, p[0]]

              # finish operation
              finish_operation(p_new)
            end
          end

          if !@points.empty? && !rectangle
            distance = text.to_l

            vector = @mouse_ip.position - @points[-1]
            vector.length = distance.to_f
            @points << @points[-1] + vector

            add_construction_geometry

            if @points[0..-2].include? @points[-1]
              finish_operation(@points)
            end
          end
        end
      rescue ArgumentError
        Sketchup.status_text = 'Invalid length'
      end

      def onLButtonDown(_flags, _x, _y, _view)
        if @mouse_ip.valid?
          # append mouse position to points array
          @points << @mouse_ip.position
          @pick_faces = @pick_faces_preview

          # create construction point and edges
          add_construction_geometry

          if (@points.length == 2) && !@force_polygon
            # try to create a rectangle
            finish_operation do |face_normal|
              rectangle = Envelop::GeometryUtils.construct_rectangle(@points[0], @points[1], face_normal)
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
        # Value Control Box label
        Sketchup.vcb_label = 'Distance'
        unless @points.empty?
          rectangle = false
          if @points.length == 1 && !@force_polygon
            p = Envelop::GeometryUtils.construct_rectangle(@points[0], @mouse_ip.position, get_face_normal_preview)
            unless p.nil?
              rectangle = true
              v1 = p[1] - p[0]
              v2 = p[2] - p[1]
              Sketchup.vcb_value = "#{v1.length.to_l}; #{v2.length.to_l}"
            end
          end

          unless rectangle
            Sketchup.vcb_value = @mouse_ip.position.distance(@points[-1]).to_l.to_s
          end
        end

        if @points.empty?
          Sketchup.status_text = 'Select start point'
        elsif @points.length == 1
          Sketchup.status_text = 'Select next point. Ctrl = toggle between rectangle and line'
        else
          Sketchup.status_text = 'Select next point'
        end
      end

      def add_construction_geometry
        Envelop::OperationUtils.operation_chain('Guide', true, lambda {
          # TODO: check if construction points/lines are necessary for inference, if so fix undo-stack littering
          @construction_entities << Sketchup.active_model.entities.add_cpoint(@points[-1])
          if @points.length > 1
            @construction_entities << Sketchup.active_model.entities.add_cline(@points[-2], @points[-1])
          end
          true
        })
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

      # @return [Geom::Vector3d]
      def get_face_normal_preview
        pick_face = @pick_faces_preview.length == 1 ? @pick_faces_preview.first : false
        pick_face ? Envelop::GeometryUtils.normal_transformation(pick_face.transform) * pick_face.entity.normal : nil
      end

      # @return [Set<PickResult>] a set with all faces, their transform and parent at x, y position
      def pick_all_faces(view, x, y)
        Set.new Envelop::GeometryUtils.pick_all_entity(view, x, y, Sketchup::Face)
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
          # clear construction geometry before creating actual lines to get a clean undo history
          erase_construction_geometry

          # try to add edges to picked face without destroying the manifoldness of the faces parent
          if pick_face
            pick_face = Envelop::OperationUtils.operation_chain('Pen Tool on Face', false, lambda {
              # remember if the parent of the picked face is manifold
              manifold_before = !pick_face.parent.nil? && pick_face.parent.manifold?

              entities = (pick_face.parent&.definition || Sketchup.active_model).entities
              Envelop::GeometryUtils.create_line(entities, pick_face.transform.inverse, points, add_all_faces: false)

              # check if the parent of the picked face is still manifold if it was before
              !manifold_before || pick_face.parent.manifold?
            })
          end

          # either there was no face or the atempt with the picked face failed
          unless pick_face
            Envelop::OperationUtils.operation_chain('Pen Tool', false, lambda {
              Envelop::GeometryUtils.create_line(Sketchup.active_model.entities, IDENTITY, points, add_all_faces: true)
              true
            })
          end

          reset_tool
          true
        else
          false
        end
      end

      def reset_tool
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
