
module Envelop
  module GeometryUtils
    
    # Search the target Entity recursively inside the given Entities and return 
    # the Entity's transformation if found or nil otherwise
    #
    # @param target [Sketchup::Entity] the target entity
    # @param entities [Sketchup::Entities, nil] the entities to search in, nil will use Sketchup.active_model.entities
    # @param transform [Geom::Transformation, nil] previous transformation, nil will use the identity transformation
    # @return [Geom::Transformation, nil]
    def self.search_entity_transform_recursive(target, entities=nil, transform=nil)
      if entities.nil? then entities = Sketchup.active_model.entities end
      if transform.nil? then transform = Geom::Transformation.new end
    
      entities.each do | entity |
        if entity == target
          return transform
        end
        if entity.is_a? Sketchup::Group or entity.is_a? Sketchup::ComponentInstance
          result = search_entity_transform_recursive(target, entity.definition.entities, transform * entity.transformation)
          if not result.nil? then return result end
        end
      end
      
      return nil
    end
  end
end
