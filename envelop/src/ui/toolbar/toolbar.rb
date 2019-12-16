# frozen_string_literal: true

require 'sketchup'

module Envelop
  module Toolbar
    def self.area_command
      cmd = UI::Command.new('Area') do
        Envelop::AreaOutput.open_dialog()
      end
      cmd.set_validation_proc do
        if Envelop::Housekeeper.house_exists?
          MF_ENABLED
        else
          MF_GRAYED
        end
      end
      cmd.small_icon = 'area.svg'
      cmd.large_icon = 'area.svg'
      cmd.tooltip = 'Area Output'
      cmd.status_bar_text = 'Calculate surface area of selection'
      cmd.menu_text = 'Area'

      cmd
    end

    def self.reload_command
      cmd = UI::Command.new('Reload') do
        Envelop.reload
      end
      cmd.small_icon = 'ToolPencilSmall.png'
      cmd.large_icon = 'ToolPencilLarge.png'
      cmd.tooltip = 'Envelop.reload'
      cmd.status_bar_text = 'Reload the envelop plugin'
      cmd.menu_text = 'Reload'

      cmd
    end

    def self.modeling_tool_add_command
      cmd = UI::Command.new('Add') do
        Envelop::ModelingTool.add_selection
      end
      cmd.set_validation_proc do
        if Sketchup.active_model.selection.empty?
          MF_GRAYED
        else
          MF_ENABLED
        end
      end
      cmd.small_icon = 'add_selection.svg'
      cmd.large_icon = 'add_selection.svg'
      cmd.tooltip = 'Add Selection'
      cmd.status_bar_text = 'Add selection to house'
      cmd.menu_text = 'Add'

      cmd
    end

    def self.modeling_tool_subtract_command
      cmd = UI::Command.new('Subtract') do
        Envelop::ModelingTool.subtract_selection
      end
      cmd.set_validation_proc do
        if Sketchup.active_model.selection.empty?
          MF_GRAYED
        else
          MF_ENABLED
        end
      end
      cmd.small_icon = 'subtract_selection.svg'
      cmd.large_icon = 'subtract_selection.svg'
      cmd.tooltip = 'Subtract Selection'
      cmd.status_bar_text = 'Subtract selection from house'
      cmd.menu_text = 'Subtract'

      cmd
    end

    def self.scale_tool_command
      cmd = UI::Command.new('Scale') do
        Envelop::ScaleTool.activate_scale_tool
      end
      cmd.small_icon = ''
      cmd.large_icon = ''
      cmd.tooltip = 'Scale model'
      cmd.status_bar_text = 'Scale model by defining a known distance'
      cmd.menu_text = 'Scale'

      cmd
    end

    def self.floor_maker_command
      cmd = UI::Command.new('Floor Maker') do
        Envelop::FloorMakerTool.activate_floor_maker_tool
      end
      cmd.small_icon = ''
      cmd.large_icon = ''
      cmd.tooltip = 'Create Floor'
      cmd.status_bar_text = 'Create a Floor at Mouseclick-Height'
      cmd.menu_text = 'Create Floor'

      cmd
    end
    
    def self.pen_tool_command
      cmd = UI::Command.new('Pen Tool') do
        Envelop::PenTool.activate_pen_tool
      end
      cmd.small_icon = 'pen_tool.svg'
      cmd.large_icon = 'pen_tool.svg'
      cmd.tooltip = 'Create Polygon or Rectangle'
      cmd.status_bar_text = 'Create Polygon or Rectangle Face'
      cmd.menu_text = 'Pen Tool'

      cmd
    end
    
    def self.pushpull_tool_command
      cmd = UI::Command.new('Push-Pull Tool') do
        Envelop::PushPullTool.activate_pushpull_tool
      end
      cmd.small_icon = 'pushpull_tool.svg'
      cmd.large_icon = 'pushpull_tool.svg'
      cmd.tooltip = 'Push-Pull'
      cmd.status_bar_text = 'Extrude a face into a volume'
      cmd.menu_text = 'Push-Pull Tool'

      cmd
    end

    unless file_loaded?(__FILE__)
      @toolbar = UI::Toolbar.new 'Envelop Toolbar'

      @toolbar = @toolbar.add_item area_command
      @toolbar = @toolbar.add_separator
      @toolbar = @toolbar.add_item pen_tool_command
      @toolbar = @toolbar.add_item pushpull_tool_command
      @toolbar = @toolbar.add_item modeling_tool_add_command
      @toolbar = @toolbar.add_item modeling_tool_subtract_command
      @toolbar = @toolbar.add_item scale_tool_command
      @toolbar = @toolbar.add_separator
      @toolbar = @toolbar.add_item floor_maker_command
      @toolbar = @toolbar.add_item reload_command

      file_loaded(__FILE__)
    end

    @toolbar.show
  end
end
