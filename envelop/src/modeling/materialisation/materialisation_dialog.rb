# frozen_string_literal: true

require 'json'

module Envelop
  module MaterialisationDialog
    # Public
    def self.show_dialog
      if @dialog&.visible?
        @dialog.bring_to_front
      else
        @dialog ||= create_dialog
        @dialog.add_action_callback('ready') do |_action_context|
          set_materials
          nil
        end
        @dialog.add_action_callback('delete_material') do |_action_context, material_name|
          Envelop::Materialisation.delete_material(material_name)
          nil
        end
        @dialog.add_action_callback('add_material') do |_action_context, material_name|
          Envelop::Materialisation.add_material(material_name)
          set_materials
          nil
        end
        @dialog.add_action_callback('select_material') do |_action_context, material_name|
          Envelop::MaterialisationTool.activate_materialisation_tool(Sketchup.active_model.materials[material_name])
          nil
        end
        @dialog.show
      end
    end

    private

    # Settings
    HTML_WIDTH = 200

    #  Methods
    def self.create_dialog
      puts('Envelop::MaterialisationDialog.create_dialog: ...')

      height = Envelop::WindowUtils.view_height_pixels - Envelop::PlanImport::HTML_HEIGHT + Envelop::WindowUtils.magic_window_size_and_positioning_const
      width = Envelop::WindowUtils.html_window_horirontal_scrollbar_width + Envelop::MaterialisationDialog::HTML_WIDTH

      html_file = File.join(__dir__, 'materialisation_dialog.html')
      options = {
        dialog_title: 'Materialisation',
        preferences_key: 'envelop.materialisation_dialog',
        min_width: width, # TODO: consider making this window resizeable. TODO: ensure these settings actually work
        max_width: width,
        min_height: height,
        max_height: height,
        style: UI::HtmlDialog::STYLE_UTILITY
      }
      dialog = UI::HtmlDialog.new(options)
      dialog.set_file(html_file)
      dialog.set_can_close do
        false # TODO: this straight up does not work on Mac (Works on Windows)
      end

      dialog.set_size(width, height) # TODO: update this as the main window is resized.
      dialog.set_position(Envelop::WindowUtils.view_width_pixels - width, Envelop::WindowUtils.sketchup_menu_and_toolbar_height) # TODO: update this as the main window is resized. # TODO: ensure window cannot be repositioned, but it needs to be able to be managed/hidden in some way

      dialog
    end

    def self.materials_as_hash_array
      res = []
      Sketchup.active_model.materials.each do |material|
        next unless material.get_attribute('material', 'user_facing')

        material_hash = {}

        material_hash['name'] = material.name
        material_hash['color_rgb'] = material.get_attribute('material', 'color_rgb')
        material_hash['color_hsl_l'] = material.get_attribute('material', 'color_hsl_l')
        material_hash['index'] = material.get_attribute('material', 'index')

        res.push(material_hash)
      end
      res
    end

    def self.set_materials
      puts 'Envelop::MaterialisationDialog.set_materials: ...'

      if @dialog.nil?
        warn '@dialog is nil, aborting...'
        return
      end

      @dialog.execute_script("setMaterials('#{materials_as_hash_array.to_json}')")
    end

    def self.reload
      if @dialog
        @dialog.close
        remove_instance_variable(:@dialog)
      end
    end
    reload
  end
end
