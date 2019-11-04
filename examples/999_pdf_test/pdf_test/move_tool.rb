require 'sketchup.rb'

class MoveTool

	def activate
		# clear the selection
		clear_selection

		# initialize variables
		@mouse_ip = Sketchup::InputPoint.new
		@picked_first_ip = Sketchup::InputPoint.new
		@object_first = nil
	end

	def deactivate(view)
		view.invalidate
	end

	def resume(view)
		update_ui
		view.invalidate
	end

	def onCancel(reason, view)
		reset_tool
		view.invalidate
	end

	def onMouseMove(flags, x, y, view)
		if picked_first_point?
			@mouse_ip.pick(view, x, y, @picked_first_ip)
		else
			@mouse_ip.pick(view, x, y)
		end
		view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
		view.invalidate
	end

	def onLButtonDown(flags, x, y, view)
	
		if picked_first_point?
			
			object_second = @mouse_ip.instance_path.root
			unless object_second.nil? || object_second == @object_first
			
				puts "picked_second_ip: #{@mouse_ip.position}"
			
				# move first object to second object
				a = @picked_first_ip.position 
				b = @mouse_ip.position
				translation_vector = b - a
				translation = Geom::Transformation.translation(translation_vector)
				
				model = Sketchup.active_model
				model.start_operation('IP6 Move Tool', true)
						
				@object_first.transformation = translation * @object_first.transformation
			
				model.commit_operation
			
				reset_tool
			end
		else 
			
			@object_first = @mouse_ip.instance_path.root
			unless @object_first.nil?
				# add the first object to the selection to highlight it
				model = Sketchup.active_model
				selection = model.selection
				selection.add(@object_first)
			
				# Set the current mouse point as the first picked point
				@picked_first_ip.copy!(@mouse_ip)
				puts "picked_first_ip: #{@picked_first_ip.position}"
			end
		end

		update_ui
		view.invalidate
	end

	# Here we have hard coded a special ID for the pencil cursor in SketchUp.
	# Normally you would use `UI.create_cursor(cursor_path, 0, 0)` instead
	# with your own custom cursor bitmap:
	#
	#   CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
	CURSOR_PENCIL = 632
	def onSetCursor
		# Note that `onSetCursor` is called frequently so you should not do much
		# work here. At most you switch between different cursor representing
		# the state of the tool.
		UI.set_cursor(CURSOR_PENCIL)
	end

	def draw(view)
		draw_preview(view)
		@mouse_ip.draw(view) if @mouse_ip.display?
	end

	def getExtents
		bb = Geom::BoundingBox.new
		bb.add(picked_points)
		bb
	end

	private

	def update_ui
		if picked_first_point?
			Sketchup.status_text = 'Select end point.'
		else
			Sketchup.status_text = 'Select start point.'
		end
	end

	def reset_tool
		@picked_first_ip.clear
		update_ui
		@object_first = nil
		clear_selection
	end

	def picked_first_point?
	@picked_first_ip.valid?
	end

	def picked_points
		points = []
		points << @picked_first_ip.position if picked_first_point?
		points << @mouse_ip.position if @mouse_ip.valid?
		points
	end

	def draw_preview(view)
		points = picked_points
		return unless points.size == 2
		view.set_color_from_line(*points)
		view.line_width = 1
		view.line_stipple = ''
		view.draw(GL_LINES, points)
	end

	def clear_selection
		model = Sketchup.active_model
		selection = model.selection
		selection.clear
	end

end # class ScaleTool

def activate_move_tool
	Sketchup.active_model.select_tool(MoveTool.new)
end