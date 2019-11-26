require_relative '../vendor/rb/os'

module Envelop
  module WindowUtils
    # Settings
    MAC_SCALING = 1.0 / UI.scale_factor # TODO: is this actually cross platform and cross screen size and dpi?
    WINDOWS_SCLAING = 1.0 / UI.scale_factor

    def self.ViewHeightPixels
      if OS.windows?
        return Sketchup.active_model.active_view.vpheight * Envelop::WindowUtils::WINDOWS_SCLAING + 8
      elsif OS.mac?
        return Sketchup.active_model.active_view.vpheight * Envelop::WindowUtils::MAC_SCALING
      else
        puts "Unrecognized Platform, window positioning and sizing is unlikely to work."
        return Sketchup.active_model.active_view.vpheight
      end
    end

    def self.ViewWidthPixels    
      if OS.windows?
        return Sketchup.active_model.active_view.vpwidth * Envelop::WindowUtils::WINDOWS_SCLAING + 8
      elsif OS.mac?
        return Sketchup.active_model.active_view.vpwidth * Envelop::WindowUtils::MAC_SCALING
      else
        puts "Unrecognized Platform, window positioning and sizing is unlikely to work."
        return Sketchup.active_model.active_view.vpwidth
      end
    end
  end
end
