require 'json'

module Envelop
  module AreaOutput
		# public
		def self.open_dialog(house = Envelop::Housekeeper.get_house)
      if !Envelop::ScaleTool.is_model_scaled
        UI.messagebox('The model must be scaled before outputting area measurements. Starting scale tool...')
        Envelop::ScaleTool.activate_scale_tool(true)
      elsif Envelop::Materialisation.house_contains_default_material
        UI.messagebox('The model still contains faces with the default material. Please asign non-default materials from the list on the right to all faces.')
      else
        area = calc_area(house)
  			@area_json = area.to_json
        DIALOG_OPTIONS[:height] = BASE_HEIGHT + area.length * 21
        Envelop::DialogUtils.show_dialog(DIALOG_OPTIONS) { |dialog| attach_callbacks(dialog) }
      end
		end

		private

    # settings
    BASE_HEIGHT = 10 + 23 + 2 + 21 + Envelop::WindowUtils.html_window_header_and_vert_scrollbar_height

    DIALOG_OPTIONS = {
      path_to_html: File.join(__dir__, 'area_output.html'),
      title: 'Area Output',
      id: 'Envelop::AreaOutput:AreaOutput',
      height: 0, width: 650,
      pos_x: 0, pos_y: 0,
      center: true,
      can_close: true,
      min_height: BASE_HEIGHT, min_width: 150,
      resizeable_height: true, resizeable_width: true
    }

    def self.attach_callbacks(dialog)
      dialog.add_action_callback("call_set_result") { |action_context|
        Envelop::DialogUtils.execute_script(DIALOG_OPTIONS[:id], "set_result('#{@area_json}')")
        nil
      }
      dialog.add_action_callback("getLengthUnit") { |action_context|
        self.get_current_unit
      }
      dialog.add_action_callback("close") { |action_context|
        Envelop::DialogUtils.close_dialog(DIALOG_OPTIONS[:id])
        nil
      }
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

        materials["Total"] = Hash.new
        materials["Total"]["index"] = Envelop::Materialisation::LAST_MATERIAL_INDEX
      end

      # extract interesting entities
      faces = group.entities.select {|entity| entity.is_a? Sketchup::Face }
      sub_groups = group.entities.select {|entity| entity.is_a? Sketchup::Group }

      # calculate faces
      faces.each do |face|
        material = face.material
        name = material.nil? ? "default" : material.name
        area = area_to_current_unit(face.area(transformation))
        direction = map_direction(get_direction(face.normal))

        if materials[name].nil?
          materials[name] = Hash.new
          materials[name]["index"] = material.get_attribute('material', 'index') # TODO handle the case where material=nil
        end

        if materials[name][direction].nil?
          materials[name][direction] = 0
        end

        if materials[name]["Total"].nil?
          materials[name]["Total"] = 0
        end

        if materials["Total"][direction].nil?
          materials["Total"][direction] = 0
        end

        if materials["Total"]["Total"].nil?
          materials["Total"]["Total"] = 0
        end

        materials[name][direction] += area
        materials[name]["Total"] += area
        materials["Total"][direction] += area
        materials["Total"]["Total"] += area
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
      pitch_angle = Z_AXIS.angle_between(normal).radians
      if pitch_angle < 45
        return "R" #Roof
      elsif pitch_angle < 135
        direction = Math.atan2(normal.y, normal.x).radians
        return ["W", "SW", "S", "SE", "E", "NE", "N", "NW", "W"][((direction + 180) / 45).round]
      else
        return "F" #Floor
      end
    end

    def self.map_direction(dir)
      if ["R", "F"].include?(dir)
        return "H"
      elsif "SE" == dir
        return "SO"
      elsif "E" == dir
        return "O"
      elsif "NE" == dir
        return "NO"
      end

      return dir
    end

    def self.reload
      remove_instance_variable(:@area_json) unless @area_json.nil?
    end
    reload
  end
end
