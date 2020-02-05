# frozen_string_literal: true

require 'sketchup'
require_relative '../../vendor/rb/os'

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
      set_icon(cmd, 'area')
      cmd.tooltip = 'Area Output'
      cmd.status_bar_text = 'Calculate surface area of selection'
      cmd.menu_text = 'Area'

      cmd
    end

    def self.reload_command
      cmd = UI::Command.new('Reload') do
        Envelop.reload
      end
      set_icon(cmd, 'reload')
      cmd.tooltip = 'Envelop.reload'
      cmd.status_bar_text = 'Reload the envelop plugin'
      cmd.menu_text = 'Reload'

      cmd
    end

    def self.scale_tool_command
      cmd = UI::Command.new('Scale') do
        Envelop::ScaleTool.activate_scale_tool
      end
      set_icon(cmd, 'scale_tool')
      cmd.tooltip = 'Scale model'
      cmd.status_bar_text = 'Scale model by defining a known distance'
      cmd.menu_text = 'Scale'

      cmd
    end

    def self.orientation_tool_command
      cmd = UI::Command.new('Orientation') do
        Envelop::OrientationTool.activate_orientation_tool
      end
      set_icon(cmd, 'orientation_tool')
      cmd.tooltip = 'Set which direction is North'
      cmd.status_bar_text = 'Set which direction is North'
      cmd.menu_text = 'Orientation'

      cmd
    end

    def self.floor_maker_command
      cmd = UI::Command.new('Floor Maker') do
        Envelop::FloorMakerTool.activate_floor_maker_tool
      end
      set_icon(cmd, 'floor_tool')
      cmd.tooltip = 'Create Floor'
      cmd.status_bar_text = 'Create a Floor at Mouseclick-Height'
      cmd.menu_text = 'Create Floor'

      cmd
    end

    def self.pen_tool_command
      cmd = UI::Command.new('Pen Tool') do
        Envelop::PenTool.activate_pen_tool
      end
      set_icon(cmd, 'pen_tool')
      cmd.tooltip = 'Create Polygon or Rectangle'
      cmd.status_bar_text = 'Create Polygon or Rectangle Face'
      cmd.menu_text = 'Pen Tool'

      cmd
    end

    def self.pushpull_command
      cmd = UI::Command.new('Push-Pull Tool') do
        Envelop::PushPullTool.activate_pushpull_tool()
      end
      set_icon(cmd, 'pushpull_tool')
      cmd.tooltip = 'Push-Pull'
      cmd.status_bar_text = 'Extrude a face into a volume and add to or remove from house'
      cmd.menu_text = 'Push-Pull Tool'

      cmd
    end

    def self.hide_plans_command
      cmd = UI::Command.new('Hide all plans') do
        Envelop::PlanManager.hide_all_plans
      end
      set_icon(cmd, 'hide_plans')
      cmd.tooltip = 'Hide all plans'
      cmd.status_bar_text = 'Hide all plans'
      cmd.menu_text = 'Hide all plans'

      cmd
    end

    def self.unhide_plans_command
      cmd = UI::Command.new('Unhide all plans') do
        Envelop::PlanManager.unhide_all_plans
      end
      set_icon(cmd, 'unhide_plans')
      cmd.tooltip = 'Unhide all plans'
      cmd.status_bar_text = 'Unhide all plans'
      cmd.menu_text = 'Unhide all plans'

      cmd
    end

    def self.open_wizard_command
      cmd = UI::Command.new('Open Wizard') do
        Envelop::Wizard.open_dialog
      end
      set_icon(cmd, 'wizard')
      cmd.tooltip = 'Open Wizard'
      cmd.status_bar_text = 'Open Wizard'
      cmd.menu_text = 'Open Wizard'

      cmd
    end

    def self.plan_manager_tool_command
      cmd = UI::Command.new('Plan Manager Tool') do
        Envelop::PlanManagerTool.activate_plan_manager_tool
      end
      set_icon(cmd, 'plan_manager')
      cmd.tooltip = 'Plan Manager Tool'
      cmd.status_bar_text = 'Move and Hide Plans'
      cmd.menu_text = 'Plan Manager Tool'

      cmd
    end

    #
    # Set the icon for the command. Assumes that path.svg and path.pdf exists
    #
    # @param cmd [UI::Command]
    # @param path [String] icon file name without extension
    #
    def self.set_icon(cmd, path)
      if OS.mac?
        cmd.small_icon = path + ".pdf"
        cmd.large_icon = path + ".pdf"
      else
        cmd.small_icon = path + ".svg"
        cmd.large_icon = path + ".svg"
      end
    end

    unless file_loaded?(__FILE__)
      @toolbar = UI::Toolbar.new 'Envelop Toolbar'

      @toolbar = @toolbar.add_item open_wizard_command

      @toolbar = @toolbar.add_separator
      @toolbar = @toolbar.add_item pen_tool_command
      @toolbar = @toolbar.add_item pushpull_command
      @toolbar = @toolbar.add_item floor_maker_command

      @toolbar = @toolbar.add_separator
      @toolbar = @toolbar.add_item scale_tool_command
      @toolbar = @toolbar.add_item orientation_tool_command
      @toolbar = @toolbar.add_item area_command

      @toolbar = @toolbar.add_separator
      @toolbar = @toolbar.add_item plan_manager_tool_command
      @toolbar = @toolbar.add_item hide_plans_command
      @toolbar = @toolbar.add_item unhide_plans_command

      @toolbar = @toolbar.add_separator
      @toolbar = @toolbar.add_item reload_command

      file_loaded(__FILE__)
    end

    @toolbar.show
  end
end
