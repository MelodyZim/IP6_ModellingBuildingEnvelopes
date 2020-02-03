# frozen_string_literal: true

require 'sketchup.rb'

module Envelop
  module ModelingTool
    # don't know what this is for, might be useful

    module_function

    # explode all groups inside the given Sketchup::Entities
    def explode_groups(entities)
      groups = entities.select { |entity| entity.is_a? Sketchup::Group }
      groups.each do |group|
        explode_groups group.entities
        group.explode
      end
    end

    def add_selection
      model = Sketchup.active_model

      Envelop::OperationUtils.operation_chain('Envelop: Add Selection to House', lambda {
        # return if selection is empty
        if model.selection.empty?
          UI.messagebox('Selection is empty')
          return false
        end

        return Envelop::Housekeeper.add_to_house(model.selection.to_a)
      })
    end

    def subtract_selection
      model = Sketchup.active_model

      Envelop::OperationUtils.operation_chain('Envelop: Remove Selection from House', lambda {
        # return if selection is empty
        if model.selection.empty?
          UI.messagebox('Selection is empty')
          return false
        end

        return Envelop::Housekeeper.remove_from_house(model.selection.to_a)
      })
    end
  end # ModelingTool
end # Examples
