# frozen_string_literal: true

require_relative '../vendor/rb/os'

module Envelop
  module WindowUtils
    # TODO: ensure this is correct for different OSs, Screen Resolutions & DPIs
    def self.HTMLWindowHeaderAndVertScrollbarHeight
      if OS.mac?
        26
      elsif OS.windows?
        62
      else
        puts 'Envelop::WindowUtils.HTMLWindowHeaderAndVertScrollbarHeight: Usupported Platfrom, returning 0. HTML Windows will likely be too small.'
        0
     end
    end

    # TODO: ensure this is correct for different OSs, Screen Resolutions & DPIs
    def self.SketchupMenuAndToolbarHeight
      if OS.mac?
        88 # TODO: this assumes Sketchup is running windowed & at max size. Either ensure or at least validate this assumption
      elsif OS.windows?
        77
      else
        puts 'Envelop::WindowUtils.SketchupMenuAndToolbarHeight: Usupported Platfrom, returning 0. HTML Windows will likely be positioned too high.'
        0
      end
    end

    if UI.scale_factor != 2.0
      puts 'Envelop::WindowUtils: UI.scale_factor != 2.0, window positioning and sizing might not work.'
    end

    def self.ViewHeightPixels
      if OS.windows?
        Sketchup.active_model.active_view.vpheight / 2.0 + MagicWindowSizeAndPositioningConst
      elsif OS.mac?
        Sketchup.active_model.active_view.vpheight / 2.0
      else
        puts 'Envelop::WindowUtils.ViewHeightPixels: Usupported Platfrom, returning Sketchup.active_model.active_view.vpheight. HTML Windows will likely be positioned much too low.'
        Sketchup.active_model.active_view.vpheight
      end
    end

    def self.ViewWidthPixels
      if OS.windows?
        Sketchup.active_model.active_view.vpwidth / 2.0 + MagicWindowSizeAndPositioningConst
      elsif OS.mac?
        Sketchup.active_model.active_view.vpwidth / 2.0
      else
        puts 'Envelop::WindowUtils.ViewWidthPixels: Usupported Platfrom, returning Sketchup.active_model.active_view.vpwidth. HTML Windows will likely be positioned much too far to the right.'
        Sketchup.active_model.active_view.vpwidth
      end
    end

    def self.MagicWindowSizeAndPositioningConst
      if OS.windows?
        8 # TODO: this + 8 is very mysterious and very unlikely to work outside of patricks machine
      elsif OS.mac?
        0
      else
        puts 'Envelop::WindowUtils.MagicWindowSizeAndPositioningConst: Usupported Platfrom, returning 0. Windows positioning and sizing is unlikely to work correctly.'
        0
      end
    end
  end
end
