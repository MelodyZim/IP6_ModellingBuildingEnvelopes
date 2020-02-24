# frozen_string_literal: true

module Envelop
  module ScaleTool
    class ScaleTool
      # TODO: consider using the input on the lower right hand side to either set line length or set how long the line should be
      PHASES = { BEFORE_FIRST_POINT: 0, BEFORE_SECOND_POINT: 2, BEFORE_SCALE: 3 }.freeze

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

      def onCancel(_reason, _view)
        Sketchup.active_model.select_tool(nil) # this will invalidate view & delete becasue phase will not be FINISHED
      end

      def draw(view)
        if @phase == PHASES[:BEFORE_SECOND_POINT] && @mouse_ip.valid?
          draw_line(view, @first_point.position, @mouse_ip.position)
        elsif @phase == PHASES[:BEFORE_SCALE]
          draw_line(view, @first_point.position, @second_point.position)
        end

        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      def getExtents
        if @phase == PHASES[:BEFORE_SECOND_POINT] && @mouse_ip.valid?
          bb = Geom::BoundingBox.new
          bb.add(@first_point.position, @mouse_ip.position)
          bb
        elsif  @phase == PHASES[:BEFORE_SCALE]
          bb = Geom::BoundingBox.new
          bb.add(@first_point.position, @second_point.position)
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

      def onLButtonDown(_flags, _x, _y, _view)
        # TODO: set first point, set second point, dialog, rescale or back to setting other point. wrap in undo
        if @phase == PHASES[:BEFORE_FIRST_POINT]
          if @mouse_ip.valid?
            @first_point.copy!(@mouse_ip)
            puts "first_point: #{@first_point.position}"
            @phase = PHASES[:BEFORE_SECOND_POINT]
            set_status_text
          else
            UI.messagebox('Could not get first point because current mouse position is invalid InputPosition.')
          end
        elsif @phase == PHASES[:BEFORE_SECOND_POINT]
          if @mouse_ip.valid?
            @second_point.copy!(@mouse_ip)
            puts "second_point: #{@second_point.position}"
            @phase = PHASES[:BEFORE_SCALE]
            set_status_text

            if scale_dialog
              Sketchup.active_model.select_tool(nil)
              @complete_callback.call unless @complete_callback.nil?
            else
              @phase = PHASES[:BEFORE_SECOND_POINT]
              set_status_text
            end
          else
            UI.messagebox('Could not get second point because current mouse position is invalid InputPosition.')
          end
        end
      end

      private

      def m_to_inch(m)
        m / 0.0254
      end

      def scale_dialog
        input = UI.inputbox(['Line length in Meters: '], ['10.0'], 'Scale the Model')
        if input
          f = input[0].to_f

          if f == 0
            UI.messagebox('Could not extract non 0 length from user input.')
            return false
          end

          current_length = @second_point.position.distance(@first_point.position)
          target_length = m_to_inch(f).to_l
          ratio = target_length / current_length

          puts "current_length: #{current_length}"
          puts "target_length: #{target_length}"
          puts "ratio: #{ratio}"

          trans = Geom::Transformation.scaling(Geom::Point3d.new, ratio)
          entities = Sketchup.active_model.entities

          Envelop::OperationUtils.operation_chain("Set Scale", false, lambda {
            group = entities.add_group(*entities)
            group.transform!(trans)
            group.explode

            Sketchup.active_model.set_attribute('Envelop::ScaleTool', 'modelIsScaled', true)

            true
          })

          # Refresh housekeeper
          Envelop::Housekeeper.get_house

          return true
        end

        false
      end

      def draw_line(view, from, to)
        view.set_color_from_line(from, to)
        view.line_width = 1
        view.line_stipple = ''
        view.draw(GL_LINES, [from, to])
      end

      def reset_tool
        # reset state
        @phase = PHASES[:BEFORE_FIRST_POINT]
        @mouse_ip = Sketchup::InputPoint.new
        @first_point = Sketchup::InputPoint.new
        @second_point = Sketchup::InputPoint.new

        set_status_text
      end

      def set_status_text
        if @phase == PHASES[:BEFORE_FIRST_POINT]
          Sketchup.status_text = 'Click point in model to start line with measurement. "Esc" to abort.'
        elsif @phase == PHASES[:BEFORE_SECOND_POINT]
          Sketchup.status_text = 'Click second point in model to finish line with measurement . "Esc" to abort.'
        elsif @phase == PHASES[:BEFORE_SCALE]
          Sketchup.status_text = 'Enter measurement of selected line in model to rescale. "Enter" to accept current measurement.'
        end
      end
    end

    def self.is_model_scaled
      Sketchup.active_model.get_attribute('Envelop::ScaleTool', 'modelIsScaled', false)
    end

    #
    # Activate the scale tool. The optional block gets executed if the tool completed successfully
    #
    def self.activate_scale_tool(&complete_callback)
      Sketchup.active_model.select_tool(Envelop::ScaleTool::ScaleTool.new(&complete_callback))
    end

    def self.reload
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
