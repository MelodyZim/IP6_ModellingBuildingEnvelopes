# Copyright 2016 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'
require_relative 'scale_tool'
require_relative 'move_tool'

module Examples
  module IP6Test
	
	def self.load_pdf
		chosen_image = UI.openpanel("Open PDF File", Dir.home, "PDF|*.pdf||")
		puts "Hello Ruby!"
	end

    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins')
      menu.add_item('IP6 Scale Tool') {
        activate_scale_tool
      }
	  menu.add_item('IP6 Move Tool') {
		activate_move_tool
	  }
      file_loaded(__FILE__)
    end

  end # module IP6Test
end # module Examples