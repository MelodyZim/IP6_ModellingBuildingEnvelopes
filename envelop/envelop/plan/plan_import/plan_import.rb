# frozen_string_literal: true

require 'tempfile'
Sketchup.require "#{File.dirname(__FILE__)}/../../vendor/rb/image_size"

module Envelop
  module PlanImport
    # Public
    def self.show_dialog
      Envelop::DialogUtils.show_dialog(DIALOG_OPTIONS) { |dialog| attach_callbacks(dialog) }
    end

    private

    # Settings
    HTML_HEIGHT = 150 + Envelop::WindowUtils.html_window_header_and_vert_scrollbar_height
    DIALOG_OPTIONS = {
      path_to_html: File.join(__dir__, 'plan_import.html'),
      title: 'Plan Import',
      id: 'Envelop::PlanImport:PlanImport',
      height: HTML_HEIGHT, width: Envelop::WindowUtils.view_width_pixels,
      pos_x: 0, pos_y: Envelop::WindowUtils.view_height_pixels - HTML_HEIGHT + Envelop::WindowUtils.sketchup_menu_and_toolbar_height
    }.freeze

    # Methods
    def self.attach_callbacks(dialog)
      dialog.add_action_callback('call_load_imported_plans') do |_action_context|
        imported_plans = Sketchup.active_model.get_attribute('Envelop::PlanImport', 'imported_plans')
        unless imported_plans.nil?
          Envelop::DialogUtils.execute_script(DIALOG_OPTIONS[:id], "load_imported_plans(#{imported_plans})")
        end
        nil
      end
      dialog.add_action_callback('import_image') do |_action_context, image|
        Envelop::PlanEdit.open_dialog(image)
        nil
      end
      dialog.add_action_callback('save_imported_plans') do |_action_context, imported_plans|
        Envelop::OperationUtils.operation_chain('Save Plan', true, lambda {
          Sketchup.active_model.set_attribute('Envelop::PlanImport', 'imported_plans', imported_plans)
          
          true # commit operation
        })
        nil
      end
    end
  end
end
