# frozen_string_literal: true

require 'json'

module Envelop
  module MaterialisationDialog
    # Public
    def self.show_dialog
      Envelop::DialogUtils.show_dialog(DIALOG_OPTIONS) { |dialog| attach_callbacks(dialog) }
    end

    private

    # Settings
    HTML_HEIGHT = Envelop::WindowUtils.view_height_pixels - Envelop::PlanImport::HTML_HEIGHT + Envelop::WindowUtils.magic_window_size_and_positioning_const
    HTML_WIDTH = Envelop::WindowUtils.html_window_horirontal_scrollbar_width + 200

    DIALOG_OPTIONS = {
      path_to_html: File.join(__dir__, 'materialisation_dialog.html'),
      title: 'Materialisation',
      id: 'Envelop::MaterialisationDialog:MaterialisationDialog',
      height: HTML_HEIGHT, width: HTML_WIDTH,
      pos_x: Envelop::WindowUtils.view_width_pixels - HTML_WIDTH, pos_y: Envelop::WindowUtils.sketchup_menu_and_toolbar_height
    }.freeze

    def self.attach_callbacks(dialog)
      dialog.add_action_callback('call_set_materials') do |_action_context|
        call_set_materials
        nil
      end
      dialog.add_action_callback('delete_material') do |_action_context, material_name|
        Envelop::Materialisation.delete_material(material_name)
        nil
      end
      dialog.add_action_callback('add_material') do |_action_context, material_name|
        Envelop::Materialisation.add_material(material_name)
        call_set_materials
        nil
      end
      dialog.add_action_callback('select_material') do |_action_context, material_name|
        Envelop::MaterialisationTool.activate_materialisation_tool(Sketchup.active_model.materials[material_name])
        nil
      end
      dialog.add_action_callback('update_color') do |_action_context, material_name, color_rgb_a|
          Envelop::Materialisation.update_color(material_name, color_rgb_a)
          call_set_materials
        nil
      end
      dialog.add_action_callback('update_base_id') do |_action_context, material_name, new_base_id|
          Envelop::Materialisation.update_base_id(material_name, new_base_id)
          call_set_materials
        nil
      end
    end

    #  Methods
    def self.call_set_materials
      Envelop::DialogUtils.execute_script(DIALOG_OPTIONS[:id], "setMaterials('#{Envelop::Materialisation.user_facing_materials_as_hash_array.to_json}')")
    end
  end
end
