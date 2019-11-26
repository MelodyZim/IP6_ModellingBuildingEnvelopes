require_relative '../vendor/rb/image_size'

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
    
    # calculate the surface area of the @house group
    # the output is a json with the result
    def self.calc_area
      faces = @house.entities.select {|entity| entity.is_a? Sketchup::Face }
      faces.each do |face|
        material = face.material
        name = material.nil? ? "default" : material.name
        puts "#{name} #{face.area} #{get_unit}^2"
      end
      @house
    end
    
    # get the current unit as a string
    def self.get_unit
      # https://sketchucation.com/forums/viewtopic.php?t=35923
      ['"', "'", "mm", "cm", "m"][Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]]
    end

		# def self.set_image
			# return if @dialog.nil?
			# puts "ruby > set_image callback"
			# @dialog.execute_script("setImage('#{@image_base64}')")
		# end

    def self.reload
      if @dialog
        @dialog.close
        remove_instance_variable(:@house)
      end
    end
    reload
  end
end
