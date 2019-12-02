require 'sketchup'

module Envelop
  module Toolbar
  
    def self.area_command
      cmd = UI::Command.new("Area") {
        Envelop::AreaOutput.open_dialog(Sketchup.active_model.selection[0])
      }
      cmd.small_icon = "area.svg"
      cmd.large_icon = "area.svg"
      cmd.tooltip = "Area Output"
      cmd.status_bar_text = "Calculate surface area of selection"
      cmd.menu_text = "Area"
      
      return cmd
    end
    
    def self.reload_command
      cmd = UI::Command.new("Reload") {
        Envelop.reload
      }
      cmd.small_icon = "ToolPencilSmall.png"
      cmd.large_icon = "ToolPencilLarge.png"
      cmd.tooltip = "Envelop.reload"
      cmd.status_bar_text = "Reload the envelop plugin"
      cmd.menu_text = "Reload"
      
      return cmd
    end
    
    def self.modeling_tool_add_command
      cmd = UI::Command.new("Add") {
        Envelop::ModelingTool.add_selection
      }
      cmd.small_icon = "add_selection.svg"
      cmd.large_icon = "add_selection.svg"
      cmd.tooltip = "Add Selection"
      cmd.status_bar_text = "Add selection to house"
      cmd.menu_text = "Add"
      
      return cmd
    end
    
    def self.modeling_tool_subtract_command
      cmd = UI::Command.new("Subtract") {
        Envelop::ModelingTool.subtract_selection
      }
      cmd.small_icon = "subtract_selection.svg"
      cmd.large_icon = "subtract_selection.svg"
      cmd.tooltip = "Subtract Selection"
      cmd.status_bar_text = "Subtract selection from house"
      cmd.menu_text = "Subtract"
      
      return cmd
    end

    unless file_loaded?(__FILE__)
      @toolbar = UI::Toolbar.new "Envelop Toolbar"
    
      @toolbar = @toolbar.add_item area_command
      @toolbar = @toolbar.add_separator
      @toolbar = @toolbar.add_item modeling_tool_add_command
      @toolbar = @toolbar.add_item modeling_tool_subtract_command
      @toolbar = @toolbar.add_separator
      @toolbar = @toolbar.add_item reload_command
      
      file_loaded(__FILE__)
    end
    
    @toolbar.show
  end
end
