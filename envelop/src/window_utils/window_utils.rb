require_relative '../vendor/rb/os'

module Envelop
  module WindowUtils
    # Settings
    MAC_SCALING = 1.0 / 2.0
    WINDOWS_SCLAING = 1.0

    def self.OSScale(value)
      if OS.windows?
        return value * Envelop::WindowUtils::WINDOWS_SCLAING
      elsif OS.mac?
        return value * Envelop::WindowUtils::MAC_SCALING
      else
        puts "Unrecognized Platform, window positioning and sizing is unliekly to work."
        return value
      end
    end

    def self.ViewHeightPixels
      OSScale(Sketchup.active_model.active_view.vpheight)
    end

    def self.ViewWidthPixels
      OSScale(Sketchup.active_model.active_view.vpwidth)
    end
  end
end
