require_relative '../vendor/rb/image_size'
require 'json'

module Envelop
  module AreaOutput
		# public

		def self.open_dialog()
			@house = Envelop::ModelingTool.search_house
			show_dialog
		end

		private

		def self.create_dialog
			html_file = File.join(__dir__, 'area_output.html')
			options = {
				:dialog_title => "Area Output",
				:preferences_key => "envelop.areaoutput",
				:style => UI::HtmlDialog::STYLE_DIALOG,
				:resizable => false,
				:width => 500,
				:height => 500,
			}
			dialog = UI::HtmlDialog.new(options)
			dialog.set_size(options[:width], options[:height]) # Ensure size is set.
			dialog.set_file(html_file)
			dialog.center
			dialog
		end

		def self.show_dialog
      if @dialog&.visible?
        @dialog.bring_to_front
      else
        @dialog ||= create_dialog
        # @dialog.add_action_callback("say") { |action_context, text|
          # puts "html > #{text}"
          # nil
        # }
        # @dialog.add_action_callback("ready") { |action_context|
          # self.set_image
          # nil
        # }
        # @dialog.add_action_callback("accept") { |action_context, image_base64, orientation|
          # puts "plan_edit accept: orientation=#{orientation}"
          # Envelop::PlanPosition.add_image(image_base64, orientation)
          # @dialog.close
          # nil
        # }
        # @dialog.add_action_callback("cancel") { |action_context|
          # @dialog.close
          # nil
        # }
        @dialog.show
      end

			@dialog.show
		end

    # calculate the surface area of the supplied Sketchup::Group
    # the output is a json with the result
    def self.calc_area(group)
      faces = group.entities.select {|entity| entity.is_a? Sketchup::Face }

      materials = Hash.new

      faces.each do |face|
        material = face.material
        name = material.nil? ? "default" : material.name
        area = face.area
        direction = get_direction(face.normal)
                
        if materials[name].nil?
          materials[name] = Hash.new
        end
        if materials[name][direction].nil?
          materials[name][direction] = 0
        end
        
        materials[name][direction] += area

      end
      
      return materials
    end

    # get the current unit as a string
    def self.get_unit
      # https://sketchucation.com/forums/viewtopic.php?t=35923
      ['"', "'", "mm", "cm", "m"][Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]]
    end

    # determine the cardinal direction of the normal, returns a string for example "N" for North
    def self.get_direction(normal)
      z_axis = Geom::Vector3d.new(0,0,1)
      pitch_angle = z_axis.angle_between(normal).radians
      if pitch_angle < 45
        return "R" #Roof
      elsif pitch_angle < 135
        direction = Math.atan2(normal.y, normal.x).radians
        return ["W", "SW", "S", "SE", "E", "NE", "N", "NW", "W"][((direction + 180) / 45).round]
      else
        return "F" #Floor
      end
    end

		# def self.set_image
			# return if @dialog.nil?
			# puts "ruby > set_image callback"
			# @dialog.execute_script("setImage('#{@image_base64}')")
		# end

    def self.reload
      if @dialog
        @dialog.close
        remove_instance_variable(:@house) unless @house.nil?
      end
    end
    reload
  end
end
