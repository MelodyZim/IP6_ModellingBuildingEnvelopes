require 'sketchup.rb'

module Envelop
  module ModelingTool
  
    # don't know what this is for, might be useful
    extend self
  
    # Search the active model for a group that has a dictionary 'house' with an attribute ishouse=true
    def search_house
      
      model = Sketchup.active_model
      entities = model.active_entities
      
      entities.each do |entity|
        if entity.is_a? Sketchup::Group
          if entity.get_attribute("house", "ishouse", default_value = false)
            return entity
          end
        end
      end
    
      nil
    end
    
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
      entities = model.active_entities
      
      # return if selection is empty
      if model.selection.empty?
        UI.messagebox('Selection is empty')
        return
      end
      
      house = search_house
      if house.nil?
        # create a new house with the selection as content
        house = entities.add_group(model.selection.to_a)
        unless house.manifold?
          # house is not valid
          entities.erase_entities(house)
          UI.messagebox('Found house but it is not manifold')
        end
        house.set_attribute("house", "ishouse", true)
        return
      end
      
      # group selected
      group_add = entities.add_group(model.selection.to_a)
      
      # add operation
      result = house.outer_shell(group_add)
      if result.nil?
        UI.messagebox('outer_shell method failed!')
      else
        result.set_attribute("house", "ishouse", true)
      end
    end
  
#    # This is an example of an observer that watches tool interactions.
#    class MyToolsObserver < Sketchup::ToolsObserver
#      def onActiveToolChanged(tools, tool_name, tool_id)
#        puts "onActiveToolChanged: #{tool_name}"
#      end
#      
#      def onToolStateChanged(tools, tool_name, tool_id, tool_state)
#        puts "onToolStateChanged: #{tool_name}:#{tool_state}"
#      end
#    end
#    
#    # This is an example of an observer that watches the application for
#    # new models and shows a messagebox.
#    class MyAppObserver < Sketchup::AppObserver
#      def onNewModel(model)
#        puts "onNewModel: #{model}"
#
#        # Here is where one might attach other observers to the new model.
#        model.selection.add_observer(MySelectionObserver.new)
#      end
#    end
#
#    # Attach the observer
#    Sketchup.add_observer(MyAppObserver.new)
#
#    unless file_loaded?(__FILE__)
#    
#      # Attach the observer.
#      Sketchup.active_model.tools.add_observer(MyToolsObserver.new)
#      
#    end
#
#    file_loaded(__FILE__)
  
  end # ModelingTool
end # Examples

# model = Sketchup.active_model
# model.start_operation('Erase faces', true)
# root_entity = model.active_entities
# group = root_entity.add_group
# entities = group.entities
# root_entity.each do |entity|
  # if entity.is_a? Sketchup::Face || entity.is_a? Sketchup::Edge
    # root_entity.erase_entities(entity)
  # end
# end
# model.commit_operation

#  
#  model = Sketchup.active_model
#  root_entity = model.active_entities
#  root_entity.add_group(root_entity.to_a)
#  g1 = root_entity.add_group(root_entity.select { |entity| entity.is_a? Sketchup::Face })
#  g1.manifold?  # check if CSG methods work
#  g1.explode
#  
#  Constructive solid geometry methods
#    Sketchup::Group.subtract
#    Sketchup::Group.intersect
#    Sketchup::Group.union
#    Sketchup::Group.outer_shell
#  
