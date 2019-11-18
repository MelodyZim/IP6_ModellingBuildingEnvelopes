require 'sketchup.rb'

module ImageCropper
	def self.open_dialog
		chosen_image = UI.openpanel("Open Image File", Dir.home, "Image|*.png;*.jpg||")

		show_dialog if chosen_image
		
		@dialog.execute_script("updateImage(#{chosen_image})")
	end
	
	def self.create_dialog
		html_file = File.join(__dir__, 'html', 'image_cropper_test.html')
		options = {
			:dialog_title => "Image Crop test",
			:preferences_key => "com.sample.plugin",
			:style => UI::HtmlDialog::STYLE_DIALOG,
			# Set a fixed size now that we know the content size.
			:resizable => false,
			:width => 350,
			:height => 530,
		}
		dialog = UI::HtmlDialog.new(options)
		dialog.set_size(options[:width], options[:height]) # Ensure size is set.
		dialog.set_file(html_file)
		dialog.center
		dialog
	end

	def self.show_dialog
		@dialog ||= self.create_dialog
		@dialog.add_action_callback("say") { |action_context, text|
			puts "html > #{text}"
			nil
		}
		# @dialog.add_action_callback("ready") { |action_context|
			# self.update_dialog
			# nil
		# }
		# @dialog.add_action_callback("accept") { |action_context, value|
			# self.update_material(value)
			# @dialog.close
			# nil
		# }
		# @dialog.add_action_callback("cancel") { |action_context, value|
			# @dialog.close
			# nil
		# }
		# @dialog.add_action_callback("save") { |action_context, value|
			# self.update_material(value)
			# nil
		# }
		@dialog.show
	end

	# Populate dialog with selected material.

	def self.update_dialog
		# return if @dialog.nil?
		# material_data = nil
		# model = Sketchup.active_model
		# if model.selection.size == 1
			# material = self.selected_material
			# if material
				# material_data = self.material_to_hash(material)
				# # Write out a material thumbnail.
				# self.generate_texture_preview(material)
			# end
		# end
		# json = material_data ? JSON.pretty_generate(material_data) : 'null'
		# @dialog.execute_script("updateMaterial(#{json})")
	end

end # module ImageCropper