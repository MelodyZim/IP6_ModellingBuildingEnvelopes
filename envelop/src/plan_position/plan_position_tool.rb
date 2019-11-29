# frozen_string_literal: true

module Envelop
  module PlanPositionTool
    class PlanPositionTool
      PHASES = { BEFORE_FIRST_POINT: 0, BEFORE_MOVE: 1, BEFORE_SECOND_POINT: 2, BEFORE_SCALE: 3, FINISHED: 10 }.freeze

      def initialize(image_obj)
        @image_obj = image_obj
      end

      def activate
        puts 'activating PlanPositionTool...'
        reset_tool
      end

      def deactivate(view)
        puts 'deactivating PlanPositionTool...'

        # no need to reset_tool, tool instance will be discarded after this

        if @phase != PHASES[:FINISHED]
          if @image_obj
            Sketchup.active_model.active_entities.erase_entities @image_obj
          end
        end
        view.invalidate
      end

      def resume(view)
        puts 'resuming PlanPositionTool...'

        set_status_text
        view.invalidate
      end

      def suspend(_view)
        puts 'suspending PlanPositionTool...'
      end

      def onCancel(_reason, _view)
        # reset_tool TODO: is removing the image and deactivating the tool the correct behaviour? should it instead just reset before the frist click?

        Sketchup.active_model.select_tool(nil) # this will invalidate view & delete becasue phase will not be FINISHED
      end

      def draw(view)
        if @phase == PHASES[:BEFORE_MOVE] || @phase == PHASES[:BEFORE_SCALE]
          draw_preview_line(view)
        end

        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      def getExtents
        if (@phase == PHASES[:BEFORE_MOVE] || @phase == PHASES[:BEFORE_SCALE]) && @mouse_ip.valid?
          bb = Geom::BoundingBox.new
          bb.add(@first_point.position, @mouse_ip.position)
          bb
        end
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        UI.set_cursor(CURSOR_PENCIL)
      end

      def onMouseMove(flags, x, y, view)
        @mouse_ip.pick(view, x, y)
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      VK_RETURN = 13
      def onKeyDown(key, repeat, flags, view)
        if key == VK_RETURN
          finish()
        end
      end

      def onLButtonDown(flags, x, y, view)
        if @phase == PHASES[:BEFORE_FIRST_POINT]
          if @mouse_ip.valid?
            @first_point.copy!(@mouse_ip)
            puts "first_point to move: #{@first_point.position}"
            @phase = PHASES[:BEFORE_MOVE]
          else
            UI.messagebox('Could not get first point to move because current mouse position is invalid InputPosition.')
          end
        elsif @phase == PHASES[:BEFORE_MOVE]
          if @mouse_ip.valid?
            puts "second_point to move: #{@mouse_ip.position}"
            move_image(@mouse_ip)
            @move_target.copy!(@mouse_ip)
            @phase = PHASES[:BEFORE_SECOND_POINT]
          else
            UI.messagebox('Could not get second point to move to because current mouse position is invalid InputPosition.')
          end
        elsif @phase == PHASES[:BEFORE_SECOND_POINT]
          if @mouse_ip.valid?
            @first_point.copy!(@mouse_ip)
            puts "first_point to scale: #{@first_point.position}"
            @phase = PHASES[:BEFORE_SCALE]
          else
            UI.messagebox('Could not get first point to scale because current mouse position is invalid InputPosition.')
          end
        elsif @phase == PHASES[:BEFORE_SCALE]
          if @mouse_ip.valid?
            puts "second_point to scale: #{@mouse_ip.position}"
            scale_image(@mouse_ip)
            finish()
          else
            UI.messagebox('Could not get second point to scale to because current mouse position is invalid InputPosition.')
          end
        end
      end

      private

      def scale_image(second_point)
        # assumes @first_point.valid? && @first_point set to useful position
        # assumes @move_target.valid? && @move_target set to useful position

        current_length = @move_target.position.distance(@first_point.position) # TODO: NOW: THIS DOES NOT WORKL?
        target_length = @move_target.position.distance(second_point.position)
        ratio = target_length / current_length

        puts "current_length: #{current_length}"
        puts "target_length: #{target_length}"
        puts "ratio: #{ratio}"

        trans = Geom::Transformation.scaling(@move_target.position, ratio)
        @image_obj.transform!(trans)
      end

      def move_image(second_point)
        # assumes @first_point.valid? && @first_point set to useful position

        vec = second_point.position - @first_point.position
        trans = Geom::Transformation.translation(vec)
        @image_obj.transform!(trans)
      end

      def finish
        @phase = PHASES[:FINISHED]

        model = Sketchup.active_model
        model.selection.clear
        model.select_tool(nil)
      end

      def draw_preview_line(view)
        # assumes @first_point.valid? && @first_point set to useful position

        if @mouse_ip.valid?
          view.set_color_from_line(@first_point.position, @mouse_ip.position)
          view.line_width = 1
          view.line_stipple = ''
          view.draw(GL_LINES, [@first_point.position, @mouse_ip.position])
        end
      end

      def reset_tool
        # reset selection
        selection = Sketchup.active_model.selection
        selection.clear
        selection.add(@image_obj)

        # reset state
        @phase = PHASES[:BEFORE_FIRST_POINT]
        @mouse_ip = Sketchup::InputPoint.new
        @first_point = Sketchup::InputPoint.new
        @move_target = Sketchup::InputPoint.new

        set_status_text
      end

      def set_status_text
        if @phase == PHASES[:BEFORE_FIRST_POINT]
          Sketchup.status_text = 'Click point on new plan. "Esc" to abort. "Enter" to accept new plan as is.'
        elsif @phase == PHASES[:BEFORE_MOVE]
          Sketchup.status_text = 'Click point on old plan to move new plan. "Esc" to abort. "Enter" to accept new plan as is.'
        elsif @phase == PHASES[:BEFORE_SECOND_POINT]
          Sketchup.status_text = 'Click second point on new plan. "Enter" to accept new plan as is. "Esc" to abort.'
        elsif @phase == PHASES[:BEFORE_SCALE]
          Sketchup.status_text = 'Click second point on old plan to scale new plan. "Enter" to accept new plan as is. "Esc" to abort.'
        end
      end
    end

    def self.activate_plan_position_tool(image_obj)
      Sketchup.active_model.select_tool(Envelop::PlanPositionTool::PlanPositionTool.new(image_obj))
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
