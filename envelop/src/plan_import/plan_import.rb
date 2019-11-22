# frozen_string_literal: true

require 'tempfile'
require_relative '../vendor/rb/image_size'

module Envelop
  module PlanImport
    # Public
    def self.show_dialog
      if @dialog&.visible?
        @dialog.bring_to_front
      else
        @dialog ||= create_dialog
        @dialog.add_action_callback('import_image') do |_action_context, string, orientation|
          Envelop::PlanEdit.open_dialog(string)
          #image = import_image(string)
          #position_image(image, orientation)
          nil
        end
        @dialog.show
      end
    end

    private

    # Settings
    HTML_HEIGHT = 150 + 26 #  TODO: verify this is correct on all platforms (+ 26 for size of title bar)

    #  Methods

    def self.create_dialog
      puts('Envelop::PlanImport.create_dialog()...')

      view = Sketchup.active_model.active_view
      html_height = Envelop::PlanImport::HTML_HEIGHT

      html_file = File.join(__dir__, 'plan_import.html')
      options = {
        dialog_title: 'Plan Import',
        preferences_key: 'envelop.planimport',
        min_height: html_height,
        max_height: html_height,
        style: UI::HtmlDialog::STYLE_UTILITY
      }
      dialog = UI::HtmlDialog.new(options)
      dialog.set_file(html_file)
      dialog.set_can_close do
        false # TODO: this straight up does not work on Mac (Works on Windows)
      end
      dialog.set_size(view.vpwidth, html_height) # TODO: update this as the window is resized & make not resizeable
      dialog.center # TODO: position calculation wrong on windows
      #dialog.set_position(0, view.vpheight - html_height) # TODO: make it so this cannot be changed?
      dialog
    end

    def self.import_image(image_base64)
      image = nil
      Tempfile.create(['plan', '.png']) do |file|
        file.binmode
        file.write(Base64.decode64(image_base64['data:image/png;base64,'.length..-1]))
        file.close

        size = ImageSize.path(file.path)

        point = Geom::Point3d.new(0, 0, 0)

        # reset cam to ensure inital orientation of image
        Envelop::CameraUtils.reset
        image = Sketchup.active_model.entities.add_image(file.path, point, size.width)
        Envelop::CameraUtils.restore
      end
      image
    end

    # TODO: this might not work different north
    # orientation: 0 = Floor, 1 = North, 2 = East, 3 = South, 4 = West
    def self.position_image(image, orientation)
      # floor
      if orientation == 0
        puts('Assuming image is already alligned')

        @floor_image ||= image

      # North
      elsif orientation == 1

        # Errect
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.East, 90.degrees)
        image.transform!(trans)

        # translate based on floor image if any set yet
        if @floor_image
          vec = Geom::Vector3d.new(Envelop::Main.North)
          vec.length = @floor_image.bounds.height

          trans = Geom::Transformation.translation(vec)
          image.transform!(trans)
        end

      # East
      elsif orientation == 2
        # Errect
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.East, 90.degrees)
        image.transform!(trans)

        # Rotate
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.Up, -90.degrees)
        image.transform!(trans)

        # Translate back to (0,0,0)
        vec = Geom::Vector3d.new(Envelop::Main.North)
        vec.length = image.bounds.height

        trans = Geom::Transformation.translation(vec)
        image.transform!(trans)

        # translate based on floor image if any set yet
        if @floor_image
          vec = Geom::Vector3d.new(Envelop::Main.East)
          vec.length = @floor_image.bounds.width

          trans = Geom::Transformation.translation(vec)
          image.transform!(trans)
        end

      # South
      elsif orientation == 3

        # Errect
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.East, 90.degrees)
        image.transform!(trans)

        # Rotate
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.Up, -180.degrees)
        image.transform!(trans)

        # Translate back to (0,0,0)
        vec = Geom::Vector3d.new(Envelop::Main.East)
        vec.length = image.bounds.width

        trans = Geom::Transformation.translation(vec)
        image.transform!(trans)

      # West
      elsif orientation == 4
        # Errect
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.East, 90.degrees)
        image.transform!(trans)

        # Rotate
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.Up, 90.degrees)
        image.transform!(trans)

      else
        warn 'Envelop::ImportPlan.position_image:  called with orientation outside of [0-5]. Image positioned as if 0.'
      end
    end

    def self.reload
      if @dialog
        @dialog.close
        remove_instance_variable(:@dialog)
      end
      remove_instance_variable(:@floor_image) if @floor_image
    end
    reload
  end
end
