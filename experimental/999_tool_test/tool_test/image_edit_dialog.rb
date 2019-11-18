require 'sketchup.rb'

module ImageEditDialog
	def self.open_dialog
		show_dialog
		# show_my_messagebox("You are using SketchUp #{Sketchup.version} with Ruby #{RUBY_VERSION}", "Hello SketchUpper!")
	end
	
	def self.create_dialog
		html_file = File.join(__dir__, '..', 'tapmodo-Jcrop-1902fbc', 'index.html') # Use external HTML
		options = {
			:dialog_title => "Cropping Demo",
			:preferences_key => "example.htmldialog.materialinspector",
			:style => UI::HtmlDialog::STYLE_DIALOG
		}
		dialog = UI::HtmlDialog.new(options)
		dialog.set_file(html_file) # Can be set here.
		dialog.center
		dialog
	end
	
	def self.show_dialog
		if @dialog && @dialog.visible?
			@dialog.bring_to_front
		else
			@dialog ||= self.create_dialog
			@dialog.show
		end
	end
	
	# https://forums.sketchup.com/t/web-html-dialog-message-box-like/90199/2
	def self.show_my_messagebox(message, title)
		properties = {
			:dialog_title => title,
			:scrollable => false,
			:width => 300,
			:height => 350
		}
		html = <<-HTML
			<html>
			<body>
			<img src="https://www.sketchup.com/themes/sketchup_www_terra/images/SU_FullColor.png" width="100%" />
			<h1>#{title}</h1>
			<p>#{message}</p>
			<div style="text-align: center">
			<button onclick="window.sketchup.close()">Close</button>
			</div>
			</body>
			</html>
		HTML
		dialog = UI::HtmlDialog.new(properties)
		dialog.set_html(html)
		dialog.add_action_callback('close') { |action_context|
			dialog.close
		}
		dialog.center
		dialog.show_modal
	end

end # module ImageEditDialog