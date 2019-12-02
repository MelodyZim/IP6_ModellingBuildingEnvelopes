# frozen_string_literal: true

require_relative '../../vendor/rb/image_size'

module Envelop
  module PlanEdit
    # public

    def self.open_dialog(image_base64)
      @image_base64 = image_base64
      show_dialog
    end

    private

    def self.create_dialog
      html_file = File.join(__dir__, 'plan_edit.html')
      options = {
        dialog_title: 'Plan Edit',
        preferences_key: 'envelop.planedit',
        style: UI::HtmlDialog::STYLE_DIALOG,
        resizable: false,
        width: 500,
        height: 500
      }
      dialog = UI::HtmlDialog.new(options)
      dialog.set_size(options[:width], options[:height]) # Ensure size is set.
      dialog.set_file(html_file)
      dialog.center
      dialog
    end

    def self.show_dialog
      if @dialog&.visible?
        set_image
        @dialog.bring_to_front
      else
        @dialog ||= create_dialog
        @dialog.add_action_callback('say') do |_action_context, text|
          puts "html > #{text}"
          nil
        end
        @dialog.add_action_callback('ready') do |_action_context|
          set_image
          nil
        end
        @dialog.add_action_callback('accept') do |_action_context, image_base64, orientation|
          puts "plan_edit accept: orientation=#{orientation}"
          Envelop::PlanPosition.add_image(image_base64, orientation)
          @dialog.close
          nil
        end
        @dialog.add_action_callback('cancel') do |_action_context|
          @dialog.close
          nil
        end
        @dialog.show
      end

      @dialog.show
    end

    def self.set_image
      puts 'Envelop::PlanEdit.set_image: ...'
      if @dialog.nil?
        warn '@dialog is nil, aborting...'
        return
      end
      @dialog.execute_script("setImage('#{@image_base64}')")
    end

    def self.reload
      if @dialog
        @dialog.close
        remove_instance_variable(:@dialog)
      end
      remove_instance_variable(:@image_base64) if @image_base64
    end
    reload
  end
end
