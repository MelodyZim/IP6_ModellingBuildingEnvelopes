require 'sketchup.rb'
require 'extensions.rb'

module Envelop
  def self.reload
    load( File.join(__dir__, 'src/main.rb'))
  end

  def self.create_extension
    ex = SketchupExtension.new('Envelop', 'src/main')
    ex.description = 'Envelop: Quickly Modelling Building Envelops Based on PDF Plans'
    ex.version     = '0.1'
    # ex.copyright   = '' # TODO ?
    ex.creator     = 'Florian Siffer & Ptatrick Ackermann'

    Sketchup.register_extension(ex, true)

    ex
  end

  unless file_loaded?(__FILE__)
    @extension = create_extension
    @extension.check
    file_loaded(__FILE__)
  end
end # Envelop
