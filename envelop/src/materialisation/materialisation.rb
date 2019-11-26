# frozen_string_literal: true

require 'json'
require_relative '../vendor/rb/color_math'

module Envelop
  module Materialisation
    # Public
    def self.show_dialog
      if @dialog&.visible?
        @dialog.bring_to_front
      else
        @dialog ||= create_dialog
        @dialog.show
      end
    end

    private

    # Settings
    HTML_WIDTH = 200
    SMALL_DEVIATION = 0.1

    #  Methods
    def self.create_dialog
      puts('Envelop::Materialisation.create_dialog()...')

      height = Envelop::WindowUtils.view_height_pixels - Envelop::PlanImport::HTML_HEIGHT + Envelop::WindowUtils.magic_window_size_and_positioning_const

      html_file = File.join(__dir__, 'materialisation.html')
      options = {
        dialog_title: 'Materialisation',
        preferences_key: 'envelop.materialisation',
        min_width: Envelop::Materialisation::HTML_WIDTH, # TODO: consider making this window resizeable. TODO: ensure these settings actually work
        max_width: Envelop::Materialisation::HTML_WIDTH,
        min_height: height,
        max_height: height,
        style: UI::HtmlDialog::STYLE_UTILITY
      }
      dialog = UI::HtmlDialog.new(options)
      dialog.set_file(html_file)
      dialog.set_can_close do
        false # TODO: this straight up does not work on Mac (Works on Windows)
      end

      dialog.set_size(Envelop::Materialisation::HTML_WIDTH, height) # TODO: update this as the main window is resized.
      dialog.set_position(Envelop::WindowUtils.view_width_pixels - Envelop::Materialisation::HTML_WIDTH, Envelop::WindowUtils.sketchup_menu_and_toolbar_height) # TODO: update this as the main window is resized. # TODO: ensure window cannot be repositioned, but it needs to be able to be managed/hidden in some way

      dialog
    end

    def self.init_materials # TODO: save material pallete per machine, independent of default materials and then use those saved materials if any
      materials = Sketchup.active_model.materials

      materials.purge_unused

      default_materials_path = html_file = File.join(__dir__, 'default_materials.json')
      default_materials = JSON.parse(File.read(default_materials_path))['default_materials']

      default_materials.each do |material_hash|
        count = 1

        base_color = ColorMath.new(material_hash['color']['r'], material_hash['color']['g'], material_hash['color']['b'])
        base_color_hsl = base_color.to_hsl

        while count <= material_hash['count']

          material = materials.add("#{material_hash['id']} #{count}")
          material.set_attribute('material', 'description', "#{material_hash['name']} #{count}") # TODO: display this somewhere
          material.color = Sketchup::Color.new(deviate_to_rgb(base_color_hsl))

          count += 1
        end
      end
    end

    def self.deviate_to_rgb(color_hsl)

      rand1 = (rand() * (Envelop::Materialisation::SMALL_DEVIATION * 2) - Envelop::Materialisation::SMALL_DEVIATION) * 100
      rand2 = (rand() * (Envelop::Materialisation::SMALL_DEVIATION * 2) - Envelop::Materialisation::SMALL_DEVIATION) * 100

      res = ColorMath.from_hsl(
        color_hsl[0],
        (color_hsl[1] + rand1).clamp(0, 100),
        (color_hsl[2] + rand2).clamp(0, 100)
      )

      res.to_rgb
    end

    def self.reload
      if @dialog
        @dialog.close
        remove_instance_variable(:@dialog)
      end
      init_materials
    end
    reload
  end
end
