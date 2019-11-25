module Envelop
  module PlanPositionTool
    class PlanPositionTool

      def initialize(image_obj)
        @image_obj = image_obj
      end

      def activate
    	  reset_tool

        puts 'activated PlanPositionTool'
      end

      def deactivate(view)
        Sketchup.active_model.active_entities.erase_entities @image_obj if @image_obj
        view.invalidate
      end

    	def resume(view)
        puts 'Resuming PlanPositionTool'

    		update_ui
    		view.invalidate
    	end

      def suspend(view)
        puts 'Suspending PlanPositionTool'
      end

      def onCancel(reason, view)
      		# reset_tool TODO: is removing the image and deactivating the tool the correct behaviour? should it instead just reset before the frist click?
          Sketchup.active_model.select_tool(nil)
      		view.invalidate
      end

    	def draw(view)
    		draw_preview(view)
    		@mouse_ip.draw(view) if @mouse_ip.display?
    	end

      def getExtents
        if @first_point && @mouse_ip.valid?
          bb = Geom::BoundingBox.new
          bb.add(@first_point.position, @mouse_ip.position)
          return bb
        end
      end

      # TODO: consider having a custom cursor like: CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursors
        UI.set_cursor(CURSOR_PENCIL)
      end

      def onMouseMove(flags, x, y, view)
        @mouse_ip.pick(view, x, y)
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        if not @first_point
          if @mouse_ip.valid?
            @first_point = Sketchup::InputPoint.new(@mouse_ip.position)
            puts "first_point: #{@first_point.position}"
          else
            UI.messagebox('Could not get first point because current mouse position is invalid InputPosition')
          end
        else
          if @mouse_ip.valid?
            puts "second_point: #{@mouse_ip.position}"
            move_image(@mouse_ip)
          else
            UI.messagebox('Could not get second point because current mouse position is invalid InputPosition')
          end
        end
      end
      #
    	# 	if picked_first_point?
      #
    	# 		object_second = @mouse_ip.instance_path.root
    	# 		unless object_second.nil? || object_second == @object_first
      #
    	# 			puts "picked_second_ip: #{@mouse_ip.position}"
      #
    	# 			# move first object to second object
    	#
    	# 			model = Sketchup.active_model
    	# 			model.start_operation('IP6 Move Tool', true)
      #
    	# 			@object_first.transformation = translation * @object_first.transformation
      #
    	# 			model.commit_operation
      #
    	# 			reset_tool
    	# 		end
    	# 	else

      private

      def move_image(second_point)
				vec = second_point.position - @first_point.position
				trans = Geom::Transformation.translation(vec)
        @image_obj.transform!(trans)

        finish
      end

      def finish
        remove_instance_variable(:@image_obj)

        model = Sketchup.active_model
        model.selection.clear
        model.select_tool(nil)
      end

      def draw_preview(view)
        if @first_point && @mouse_ip.valid?
      		view.set_color_from_line(@first_point.position, @mouse_ip.position)
      		view.line_width = 1
      		view.line_stipple = ''
      		view.draw(GL_LINES, [@first_point.position, @mouse_ip.position])
        end
      end

      def reset_tool
        selection = Sketchup.active_model.selection
      	selection.clear
        selection.add(@image_obj)

        @mouse_ip = Sketchup::InputPoint.new
        remove_instance_variable(:@first_point) if @first_point

        update_ui
      end

      def update_ui
        if !@first_point
          Sketchup.status_text = 'Click point on new plan. "Esc" to abort.'
        else
          Sketchup.status_text = 'Click point on old plan to move new plan. "Esc" to abort.'
        end
      end
    end

    def self.activate_plan_position_tool(image_obj)
    	Sketchup.active_model.select_tool(Envelop::PlanPositionTool::PlanPositionTool.new(image_obj))
    end

    def self.reload()
      Sketchup.active_model.select_tool(nil)
    end
    reload
  end
end
