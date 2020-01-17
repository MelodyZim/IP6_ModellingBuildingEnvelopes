
module Envelop
  module GeometryUtils
    
    #
    # Copy the face into the given Entities. The Face is transformed by the specified Transform and/or
    # an optional block that takes as input a Point3d and should return a Point3d
    #
    # @param face [Sketchup::Face] the face to copy
    # @param entities [Sketchup::Entities] the copied face is added to the specified Entities
    # @param transform [Geom::Transfomration] the transformation
    #
    # @return [Sketchup::Face] the new Face
    #
    def self.copy_face (face, entities=Sketchup.active_model.entities, transform=IDENTITY, &block)
      # copy outer loop
      new_face = entities.add_face(copy_loop(face.outer_loop, entities, transform, &block))

      # create a hole for every inner loop
      face.loops.each do |loop|
        unless loop.outer?
          hole = entities.add_face(copy_loop(loop, entities, transform, &block))
          hole.erase!
        end
      end
      
      return new_face
    end

    #
    # Copy the edges of the Loop into the given Entities. The Edges are transformed by the specified Transform and/or
    # an optional block that takes as input a Point3d and should return a Point3d
    #
    # @param loop [Sketchup::Loop] the loop to copy
    # @param entities [Sketchup::Entities] the copied edges are added to the specified Entities
    # @param transform [Geom::Transformation] the transformation
    #
    # @return [Array<Sketchup::Edge>] the new edges
    #
    def self.copy_loop (loop, entities=Sketchup.active_model.entities, transform=IDENTITY)
      result = Array.new
      loop.edges.each do |edge|
        s = transform * edge.start.position
        e = transform * edge.end.position
        if block_given?
          s = yield s
          e = yield e
        end
        result << entities.add_line(s, e)
      end
      return result
    end
    
    #
    # Search the target Entity recursively inside the given Entities and return 
    # the Entity's transformation if found or nil otherwise
    #
    # @param target [Sketchup::Entity] the target entity
    # @param entities [Sketchup::Entities] the entities to search in, defaults to Sketchup.active_model.entities
    # @param transform [Geom::Transformation] previous transformation, defaults to the identity transformation
    #
    # @return [Geom::Transformation, nil]
    #
    def self.search_entity_transform_recursive(target, entities=Sketchup.active_model.entities, transform=IDENTITY)
      entities.each do |entity|
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
