# frozen_string_literal: true

Sketchup.require "#{File.dirname(__FILE__)}/../../vendor/rb/image_size"

module Envelop
  module PlanEdit
    # public
    def self.open_dialog(image_base64)
      @image_base64 = image_base64
      Envelop::DialogUtils.show_dialog(DIALOG_OPTIONS) { |dialog| attach_callbacks(dialog) }
    end

    private

    # settings
    DIALOG_OPTIONS = {
      path_to_html: File.join(__dir__, 'plan_edit.html'),
      title: 'Plan Edit',
      id: 'Envelop::PlanEdit:PlanEdit',
      height: 500, width: 500,
      pos_x: 0, pos_y: 0,
      center: true,
      can_close: true,
      resizeable_width: true,
      resizeable_height: true,
      min_height: 350, min_width: 350
    }.freeze

    def self.attach_callbacks(dialog)
      dialog.add_action_callback('call_set_image') do |_action_context|
        Envelop::DialogUtils.execute_script(DIALOG_OPTIONS[:id], "setImage('#{@image_base64}')")
        nil
      end
      dialog.add_action_callback('call_set_north') do |_action_context|
        north = Sketchup.active_model.get_attribute("Envelop::OrientationTool", "northAngle", Math::PI / 2).radians
        Envelop::DialogUtils.execute_script(DIALOG_OPTIONS[:id], "setNorth('#{north}')")
        nil
      end
      dialog.add_action_callback('accept') do |_action_context, image_base64, orientation|
        puts "plan_edit accept: orientation=#{orientation}"
        Envelop::PlanPosition.add_image(image_base64, orientation)
        Envelop::DialogUtils.close_dialog(DIALOG_OPTIONS[:id])
        nil
      end
      dialog.add_action_callback('cancel') do |_action_context|
        Envelop::DialogUtils.close_dialog(DIALOG_OPTIONS[:id])
        nil
      end
    end

    def self.reload
      remove_instance_variable(:@image_base64) if @image_base64
    end
    reload
  end
end
