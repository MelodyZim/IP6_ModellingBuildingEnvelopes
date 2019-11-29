# frozen_string_literal: true

require_relative '../vendor/rb/os'

module Envelop
  module WindowUtils
    # TODO: ensure this is correct for different OSs, Screen Resolutions & DPIs
    def self.html_window_header_and_vert_scrollbar_height
      if OS.mac?
        26
      elsif OS.windows?
        62
      else
        warn 'Envelop::WindowUtils.HTMLWindowHeaderAndVertScrollbarHeight: Usupported Platfrom, returning 0. HTML Windows will likely be too small.'
        0
     end
    end

    # TODO: ensure this is correct for different OSs, Screen Resolutions & DPIs
    def self.sketchup_menu_and_toolbar_height
      if OS.mac?
        88 # TODO: this assumes Sketchup is running windowed & at max size. Either ensure or at least validate this assumption
      elsif OS.windows?
        77
      else
        warn 'Envelop::WindowUtils.SketchupMenuAndToolbarHeight: Usupported Platfrom, returning 0. HTML Windows will likely be positioned too high.'
        0
      end
    end

    if UI.scale_factor != 2.0
      warn 'Envelop::WindowUtils: UI.scale_factor != 2.0, window positioning and sizing might not work.'
    end

    def self.view_height_pixels
      if OS.windows?
        Sketchup.active_model.active_view.vpheight / 2.0 + magic_window_size_and_positioning_const
      elsif OS.mac?
        Sketchup.active_model.active_view.vpheight / 2.0
      else
        warn 'Envelop::WindowUtils.ViewHeightPixels: Usupported Platfrom, returning Sketchup.active_model.active_view.vpheight. HTML Windows will likely be positioned much too low.'
        Sketchup.active_model.active_view.vpheight
      end
    end

    def self.view_width_pixels
      if OS.windows?
        Sketchup.active_model.active_view.vpwidth / 2.0 + magic_window_size_and_positioning_const
      elsif OS.mac?
        Sketchup.active_model.active_view.vpwidth / 2.0
      else
        warn 'Envelop::WindowUtils.ViewWidthPixels: Usupported Platfrom, returning Sketchup.active_model.active_view.vpwidth. HTML Windows will likely be positioned much too far to the right.'
        Sketchup.active_model.active_view.vpwidth
      end
    end

    def self.magic_window_size_and_positioning_const
      if OS.windows?
        8 # TODO: this + 8 is very mysterious and very unlikely to work outside of patricks machine
      elsif OS.mac?
        0
      else
        warn 'Envelop::WindowUtils.MagicWindowSizeAndPositioningConst: Usupported Platfrom, returning 0. Windows positioning and sizing is unlikely to work correctly.'
        0
      end
    end
  end
end
