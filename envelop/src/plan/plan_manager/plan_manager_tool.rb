# frozen_string_literal: true

module Envelop
  module PlanManagerTool
    class PlanManagerTool
      PHASES = { NEUTRAL: 0, DRAGGING: 1, MOVING: 2 }.freeze

      def activate
        puts 'activating PlanManagerTool...'

        reset_tool
      end

      def deactivate(view)
        puts 'deactivating PlanManagerTools...'

        view.invalidate # unsure if this is needed
      end

      def resume(view)
        # puts 'resuming PlanManagerTool...'
        set_status_text
        view.invalidate
      end

      def suspend(_view)
        # puts 'suspending PlanManagerTool...'
      end

      def onCancel(_reason, _view)
        @plan.transform!(@pushpull_vector.reverse) unless @pushpull_vector.nil?
        Sketchup.active_model.select_tool(nil) # this will invalidate view & deactivate tool
      end

      def draw(view)
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_OPEN_HAND = 671 # open hand # TODO: put a bunch of these into some utils
      def onSetCursor
        UI.set_cursor(CURSOR_OPEN_HAND) # TODO: this totally doesn't work reliably on mac
      end

      def onMouseMove(_flags, x, y, view)
        # hide selected plan to ignore while picking
        @plan.visible = false unless @plan.nil?

        @mouse_ip.pick(view, x, y)

        # show plan again
        @plan.visible=true unless @plan.nil?

        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?

        if (@phase == PHASES[:DRAGGING]) || (@phase == PHASES[:MOVING])
          line = [@origin, @direction]

          if @mouse_ip.edge.nil? && @mouse_ip.vertex.nil? && @mouse_ip.face.nil?
            camera_ray = view.pickray(x, y)
            target = Geom.closest_points(line, camera_ray)[0]
          else
            target = @mouse_ip.position.project_to_line(line)
          end

          unless @pushpull_vector.nil?
            @plan.transform!(@pushpull_vector.reverse)
          end

          @pushpull_vector = target - @origin

          @plan.transform!(@pushpull_vector)
        end

        view.invalidate
      end

      CLICK_DRAG_THRESHOLD_MS = 300 # TODO: make global
      def onLButtonUp(_flags, _x, _y, _view)
        if @phase == PHASES[:DRAGGING]
          elapsed_ms_since_lbuttondown_time = (Time.now - @lbuttondown_time) * 1000.0
          if elapsed_ms_since_lbuttondown_time > CLICK_DRAG_THRESHOLD_MS
            reset_dragging_state
          else
            @phase = PHASES[:MOVING]
          end
        end
      end

      def onLButtonDown(_flags, x, y, view)
        if @phase == PHASES[:NEUTRAL]
          @lbuttondown_time = Time.now
          pick_res = Envelop::GeometryUtils.pick_image(view, x, y)

          if !pick_res.nil?
            @phase = PHASES[:DRAGGING]
            @plan = pick_res.parent
            @origin =  @mouse_ip.position
            @direction = Envelop::GeometryUtils.normal_transformation(pick_res.transform) * pick_res.entity.normal
          else
            reset_dragging_state
            puts 'Envelop::PlanMangerTool::PlanManagerTool.onLButtonDown: could not pick image from onLButtonDown.'
          end
        else
          reset_dragging_state
        end
      end

      def onLButtonDoubleClick(_flags, x, y, view)
        @plan.transform!(@pushpull_vector.reverse) unless @pushpull_vector.nil?
        reset_dragging_state
        
        pick_res = Envelop::GeometryUtils.pick_image(view, x, y)
        if !pick_res.nil?
          Envelop::PlanManager.hide_plan(pick_res.parent)
        else
          puts 'Envelop::PlanMangerTool::PlanManagerTool.onLButtonDoubleClick: could not pick image from onLButtonDoubleClick.'
        end
      end

      private

      def reset_dragging_state
        @phase = PHASES[:NEUTRAL]
        @plan = nil
        @origin = nil
        @direction = nil
        @pushpull_vector = nil
        @lbuttondown_time = nil
      end

      def reset_tool
        # reset state
        reset_dragging_state
        @mouse_ip = Sketchup::InputPoint.new

        set_status_text
      end

      def set_status_text # TODO: now: proper text for phases
        if @phase == PHASES[:NEUTRAL]
          Sketchup.status_text = 'Drag any plan to move it along it\'s axis. Doubleclick it to hide it. "Esc" to abort.'
        elsif @phase == PHASES[:DRAGGING]
          Sketchup.status_text = 'Keep dragging plan to move it along it\'s axis. "Esc" to abort.'
        elsif @phase == PHASES[:MOVING]
          Sketchup.status_text = 'Move cursor to move plan. Click to confirm new position. "Esc" to abort.'
        end
      end
    end

    def self.activate_plan_manager_tool
      Sketchup.active_model.select_tool(Envelop::PlanManagerTool::PlanManagerTool.new)
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
    end
  end
