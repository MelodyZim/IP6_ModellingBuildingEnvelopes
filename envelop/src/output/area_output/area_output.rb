require 'json'

module Envelop
  module AreaOutput
		# public
		def self.open_dialog(house = Envelop::Housekeeper.get_house)
      if !Envelop::ScaleTool.scaled
        UI.messagebox('The model must be scaled before outputting area measurements. Starting scale tool...')
        Envelop::ScaleTool.activate_scale_tool(true)
      else
  			@house = house
  			show_dialog
      end
		end

		private

		def self.create_dialog
			html_file = File.join(__dir__, 'area_output.html')
			options = {
				:dialog_title => "Area Output",
				:preferences_key => "envelop.areaoutput",
				:style => UI::HtmlDialog::STYLE_DIALOG,
				:resizable => true,
				:width => 600,
				:height => 255,
			}
			dialog = UI::HtmlDialog.new(options)
			dialog.set_size(options[:width], options[:height]) # Ensure size is set.
			dialog.set_file(html_file)
			dialog.center
			dialog
		end

		def self.show_dialog
      if @dialog&.visible?
        set_area
        @dialog.bring_to_front
      else
        @dialog ||= create_dialog
        @dialog.add_action_callback("say") { |action_context, text|
          puts "html > #{text}"
          nil
        }
        @dialog.add_action_callback("ready") { |action_context|
          puts "Envelop::AreaOutput.show_dialog: action_callback('ready') ..."
          self.set_area
          nil
        }
        @dialog.add_action_callback("getLengthUnit") { |action_context|
          self.get_current_unit
        }
        # @dialog.add_action_callback("accept") { |action_context, image_base64, orientation|
          # puts "plan_edit accept: orientation=#{orientation}"
          # Envelop::PlanPosition.add_image(image_base64, orientation)
          # @dialog.close
          # nil
        # }
        @dialog.add_action_callback("close") { |action_context|
          @dialog.close
          nil
        }
        @dialog.show
      end

			@dialog.show
		end

    def self.set_area
			return if @dialog.nil?
			@dialog.execute_script("set_result('#{calc_area(@house).to_json}')")
		end

    # calculate the total surface area separated by ordinal direction and material of all the faces (Sketchup::Face)
    # of the supplied group, nested groups are resolved recursively
    # @param group [Sketchup::Group] the group to examine
    # @param transformation [Geom::Transformation] the transformation of parent groups
    # @param materials [Hash] hash to append the results or nil to create a new one
    # @return [Hash] the total surface area separated by ordinal direction and material
    def self.calc_area(group, transformation=Geom::Transformation.new, materials=nil)
      transformation *= group.transformation
      if materials.nil?
        materials = Hash.new
      end

      # extract interesting entities
      faces = group.entities.select {|entity| entity.is_a? Sketchup::Face }
      sub_groups = group.entities.select {|entity| entity.is_a? Sketchup::Group }

      # calculate faces
      faces.each do |face|
        material = face.material
        name = material.nil? ? "default" : material.name
        area = area_to_current_unit(face.area(transformation))
        direction = get_direction(face.normal)

        if materials[name].nil?
          materials[name] = Hash.new
        end
        if materials[name][direction].nil?
          materials[name][direction] = 0
        end

        materials[name][direction] += area
      end

      # calculate sub_groups
      sub_groups.each do |group|
        calc_area(group, transformation, materials)
      end

      return materials
    end

    # get the current unit as a string
    def self.get_current_unit
      # https://sketchucation.com/forums/viewtopic.php?t=35923
      ['"', "'", "mm", "cm", "m"][Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]]
    end

    # convert internal square inch float to current unit area
    def self.area_to_current_unit (area)
      current_unit_index = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]

      transformations = [
        -> (inch) {inch},             # inch^2 => inch^2
        -> (inch) {inch / 12**2},     # inch^2 => foot^2
        -> (inch) {inch * 25.4**2},   # inch^2 => mm^2
        -> (inch) {inch * 2.54**2},   # inch^2 => cm^2
        -> (inch) {inch * 0.0254**2}, # inch^2 => m^2
      ]

      transformations[current_unit_index].call(area)
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

    def self.reload
      if @dialog
        @dialog.close
        remove_instance_variable(:@dialog)
      end
      remove_instance_variable(:@house) unless @house.nil?
    end
    reload
  end
end
