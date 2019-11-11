# Copyright 2016 Trimble Inc
# Licensed under the MIT license

require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module IP6Test

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Tool test', 'tool_test/main')
      ex.description = 'SketchUp Ruby API test importing pdf as reference images.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Trimble Navigations © 2016'
      ex.creator     = 'SketchUp'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end # module IP6Test
end # module Examples
