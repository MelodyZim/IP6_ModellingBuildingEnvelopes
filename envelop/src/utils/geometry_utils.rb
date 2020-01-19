# frozen_string_literal: true

module Envelop
  module GeometryUtils
    #
    # Copy the face and create a group that contains the volume defined by transforming the
    # face vertices with the supplied block
    #
    # @param face [Sketchup::Face] Face to pushpull
    # @param transform [Geom::Transformation] Transformation of the face
    # @param entities [Sketchup::Entities]  group with the result gets added to this entities
    # @param &transform_point [Proc] block that maps a point to another point
    #
    # @return [Sketchup::Group] the group that contains the result
    #
    def self.pushpull_face(face, transform: IDENTITY, entities: Sketchup.active_model.entities, &transform_points)
      # create a new group to holds the result
      group = entities.add_group

      # add the starting face to the group
      start_face = Envelop::GeometryUtils.copy_face(face, group.entities, transform)

      # add the top face to the group
      top_face = Envelop::GeometryUtils.copy_face(face, group.entities, transform, &transform_points)

      # orient the start and top face
      v = top_face.bounds.center - start_face.bounds.center
      start_face.reverse! if v.dot(start_face.normal) > 0
      top_face.reverse! if v.dot(top_face.normal) < 0

      # add the vertical walls to the group
      start_face.edges.each do |edge|
        s = edge.start.position
        e = edge.end.position
        s_proj = transform_points.call(s)
        e_proj = transform_points.call(e)
        if e != e_proj && s != s_proj
          group.entities.add_face(s, e, e_proj, s_proj)
        elsif e == e_proj && s != s_proj
          group.entities.add_face(s, e, s_proj)
        elsif e != e_proj && s == s_proj
          group.entities.add_face(s, e, e_proj)
        end
      end

      group
    end

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
    def self.copy_face(face, entities = Sketchup.active_model.entities, transform = IDENTITY, &block)
      # copy outer loop
      new_face = entities.add_face(copy_loop(face.outer_loop, entities, transform, &block))

      # create a hole for every inner loop
      face.loops.each do |loop|
        unless loop.outer?
          hole = entities.add_face(copy_loop(loop, entities, transform, &block))
          hole.erase!
        end
      end

      new_face
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
    def self.copy_loop(loop, entities = Sketchup.active_model.entities, transform = IDENTITY)
      result = []
      loop.edges.each do |edge|
        s = transform * edge.start.position
        e = transform * edge.end.position
        if block_given?
          s = yield s
          e = yield e
        end
        result << entities.add_line(s, e)
      end
      result
    end

    #
    # Erase a face and all its edges. Edges connected to other faces are spared
    #
    # @param face [Sketchup::Face] the face to erase
    #
    def self.erase_face(face)
      edges = face.edges
      face.erase!
      edges.each do |e|
        e.erase! if e.faces.empty?
      end
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
    def self.search_entity_transform_recursive(target, entities = Sketchup.active_model.entities, transform = IDENTITY)
      entities.each do |entity|
        return transform if entity == target

        if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
          result = search_entity_transform_recursive(target, entity.definition.entities, transform * entity.transformation)
          return result unless result.nil?
        end
      end

      nil
    end

    #
    # Generate a linear transformation that transforms the given points into the specified new points
    #
    # @param original_points [Array<Sketchup::Point3d>] three original points
    # @param new_points [Array<Sketchup::Point3d>] three new points
    #
    # @return [Geom::Transformation] transformation that turns original points into new points
    #
    def self.transformation_from_point_mapping(original_points, new_points)
      return nil if original_points.length != 3 || new_points.length != 3

      original_points = original_points.map { |p| p.to_a << 1 }
      original_points += [0, 0, 0, 1]
      new_points = new_points.map { |p| p.to_a << 1 }
      new_points += [0, 0, 0, 1]
      # NOTE Geom::Transformation.invert! fails silently if the transformation is not invertible
      # see: https://forums.sketchup.com/t/bug-calling-inverse-on-a-non-invertible-transformation-return-the-original-transformation-without-any-warning/25878
      v_new = Geom::Transformation.new(new_points.flatten!)
      v_old_inv = Geom::Transformation.new(original_points.flatten!).invert!
      v_new * v_old_inv
    end

    #
    # Retrieve the transformation matrix for normal vectors
    #
    # @param transform [Geom::Transformation]
    #
    def self.normal_transformation(transform)
      transpose! transform.inverse
    end

    #
    # Set the Transfromation Matrix to its transpose
    #
    # @param transform [Geom::Transformation] Transformation Matrix to transpose
    #
    def self.transpose!(transform)
      original = transform.to_a
      transpose = Array.new(16) { |i| original[(i % 4) * 4 + (i / 4)] }
      transform.set!(transpose)
    end

    #
    # Retrieve an entity of the given type using a Sketchup::PickHelper
    # Entities closer to the root of the hierarchy are prefered
    #
    # @param view [Sketchup::View]
    # @param x [Integer]
    # @param y [Integer]
    # @param type [Class]
    #
    # @return [Array(Sketchup::Entity, Sketchup::Transformation), nil] The found entity and its transformation or nil if nothing was found
    #
    def self.pick_entity(view, x, y, type)
      # pickhelper guide: http://www.thomthom.net/thoughts/2013/01/pickhelper-a-visual-guide/

      entity = nil
      transform = nil
      depth = nil

      ph = view.pick_helper(x, y)
      ph.count.times do |i|
        leaf = ph.leaf_at(i)
        next unless leaf.is_a? type

        if depth.nil? || ph.depth_at(i) < depth
          entity = leaf
          transform = ph.transformation_at(i)
        end
      end

      entity.nil? ? nil : [entity, transform]
    end

    #
    # Draw the given points as a continuous line
    # if color is nil the default Sketchup axis colors are used
    #
    # @param view [Sketchup::View]
    # @param color [Sketchup::Color, String, nil] the color to use
    # @param points [Array<Sketchup::Point3d>] Array of points to draw
    #
    def self.draw_lines(view, color, *points)
      if color.nil?
        (1..points.length - 1).each do |i|
          view.set_color_from_line(points[i - 1], points[i])
          view.draw_line(points[i - 1], points[i])
        end
      else
        view.drawing_color = color
        view.draw_polyline points
      end
    end
  end
end
