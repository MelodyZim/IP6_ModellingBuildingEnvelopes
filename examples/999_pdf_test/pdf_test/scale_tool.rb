require 'sketchup.rb'

class ScaleTool

  def activate
	@mouse_ip = Sketchup::InputPoint.new
	@picked_first_ip = Sketchup::InputPoint.new
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
		# Show a text box for the user to input the actual length of the line
		prompts = ["Length of the line?"]
		defaults = ["10"]
		input = UI.inputbox(prompts, defaults, "Scale tool.")
		puts input
		if input
			# the user clicked OK
			begin
				target_length = input[0].to_l
				puts "target_length: #{target_length}"
				if target_length > 0
					# the user entered a valid length greater than zero
					# we can now calculate the necessary scaling for the selected objects
					
					a = @mouse_ip.position
					b = @picked_first_ip.position
					
					current_length = a.distance(b)
					
					scale_ratio = target_length / current_length
					puts "scale_ratio: #{scale_ratio}"
					scale_transform = Geom::Transformation.scaling(scale_ratio)
					
					# scale the current selection with the scale_transform matrix
					model = Sketchup.active_model
					model.start_operation('IP6 Scale Tool', true)
					selection = model.selection
					
					if selection.count == 0
						puts "nothing to scale, selection is empty!"
					end
					
					selection.each do |obj|
						# skip things that don't have a transformation for example Edges
						if obj.respond_to?("transformation")
							obj.transformation *= scale_transform
						end
					end
					
					model.commit_operation
				end
			rescue ArgumentError => er
				# The input could not be converted to a Length
				puts er
				# Sketchup.status_text = er
			end
		end
	
		reset_tool
		
	else 
		# Set the current mouse point as the first picked point
		@picked_first_ip.copy!(@mouse_ip)
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

end # class ScaleTool

def activate_scale_tool
  Sketchup.active_model.select_tool(ScaleTool.new)
end