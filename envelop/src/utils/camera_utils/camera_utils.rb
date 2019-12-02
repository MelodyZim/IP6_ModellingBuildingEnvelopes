module Envelop
    module CameraUtils

      def self.reset
        cam_ref = Sketchup.active_model.active_view.camera
        @camera = Sketchup::Camera.new(cam_ref.eye, cam_ref.target, cam_ref.up)
        cam_ref = Sketchup::Camera.new(NEUTRAL_EYE, NEUTRAL_TARGET, NEUTRAL_UP)
      end

      def self.restore
          if @camera
            Sketchup.active_model.active_view.camera = @camera
            remove_instance_variable(:@camera)
          else
            puts("Envelop::CameraUtils.restore: no previous camera to restore found. Call Envelop::CameraUtils.reset before .restore.")
          end
      end

      private

      # Settings
      NEUTRAL_EYE = [0, -10, 3]
      NEUTRAL_TARGET = [0,0,0]
      NEUTRAL_UP = Z_AXIS

      #  Methods

      def self.reload
        if @camera
          remove_instance_variable(:@camera)
        end
      end
      reload

    end
end
