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
    # @return [Geom::Transformation]
    #
    def self.normal_transformation(transform)
      transpose! transform.inverse
    end

    #
    # Set the Transfromation Matrix to its transpose
    #
    # @param transform [Geom::Transformation] Transformation Matrix to transpose
    #
    # @return [Geom::Transformation]
    #
    def self.transpose!(transform)
      original = transform.to_a
      transpose = Array.new(16) { |i| original[(i % 4) * 4 + (i / 4)] }
      transform.set!(transpose)
    end

    #
    # Create Sketchup::Edges as children of the specified Sketchup::Entities that form a line
    #
    # @param entities [Sketchup::Entities] the entities that will contain the added edges
    # @param transform [Geom::Transformation] the transformation to apply to the points
    # @param points [Array<Geom::Point3d>] Array of the points of a continuous line
    # @param add_all_faces [Boolean] whether all adjacent faces should be added, if false
    #   Sketchup::Edge.find_faces is only called for edges with no initial faces
    #
    # @return [Numeric] the number of faces created
    #
    def self.create_line(entities, transform, points, add_all_faces: true)
      points = points.map { |p| transform * p }
      edges_to_check = []
      points[0..-2].zip(points[1..-1]).each do |line|
        edge = entities.add_line(line[0], line[1])
        edges_to_check << edge if edge && (edge.faces.empty? || add_all_faces)
      end

      # add faces and return the total count of faces created
      edges_to_check.map(&:find_faces).sum
    end

    #
    # Construct a rectangle from two points. The input points are on the
    # diagonal of the resulting rectangle. One side of the rectangle is
    # always perpendicular to the Z-Axis. If p1 and p2 form a line parallel
    # to an axis then the result is nil.
    #
    # @param p1 [Geom::Point3d] the first Point
    # @param p2 [Geom::Point3d] the second Point
    # @param face_normal [Geom::Vector3d, nil] the normal of the plane in which
    #   the rectangle lies, if nil the closest plane X/Y, X/Z or Y/Z is used
    #
    # @return [Array<Geom::Point3d>, nil] an array of points of length 4
    #   that make up a rectangle or nil if no rectangle was found
    #
    def self.construct_rectangle(p1, p2, face_normal = nil)
      # determine the face_normal
      if face_normal.nil?
        # form the rectangle on the plane perpendicular to the axis with the smallest absolute difference
        abs_diagonal = (p2 - p1).to_a.map(&:abs)
        face_normal = [X_AXIS, Y_AXIS, Z_AXIS][abs_diagonal.index(abs_diagonal.min)]
      end

      # project the second point on the plane defined by the first point and the normal vector
      p2 = p2.project_to_plane([p1, face_normal])
      diagonal = p2 - p1

      # return if the points are at the same location
      return nil unless diagonal.valid?

      if Z_AXIS.cross(face_normal).valid?
        # axes on the face (perpendicular to the face normal)
        right_axis = Z_AXIS.cross(face_normal)
        up_axis = right_axis.cross(face_normal)

        # check if the diagonal is parallel to a face axis
        if diagonal.parallel?(right_axis) || diagonal.parallel?(up_axis)
          nil
        else
          # decompose diagonal vector into v_up and v_right
          # right_axis.z is always zero because it is perpendicular to Z_AXIS
          s = (diagonal.z / up_axis.z)
          v_up = Geom::Vector3d.new(up_axis.to_a.map { |c| c * s })
          v_right = diagonal - v_up

          [p1, p1 + v_right, p2, p1 + v_up]
        end
      else
        # check if p1 and p2 form a line parallel to a basic axis
        if diagonal.parallel?(X_AXIS) || diagonal.parallel?(Y_AXIS)
          nil
        else
          [
            p1,
            Geom::Point3d.new(p1.x, p2.y, p1.z),
            Geom::Point3d.new(p2.x, p2.y, p1.z),
            Geom::Point3d.new(p2.x, p1.y, p1.z)
          ]
        end
      end
    end

    #
    # Retrieve an entity of the given type using a Sketchup::PickHelper
    # Entities closer to the root of the hierarchy are prefered
    # The entities inside a Sketchup::Image are omitted
    #
    # @param view [Sketchup::View]
    # @param x [Integer]
    # @param y [Integer]
    # @param type [Class]
    #
    # @return [Array(Sketchup::Entity, Sketchup::Transformation), nil] The found entity and its transformation or nil if nothing was found
    #
    def self.pick_entity(view, x, y, type)
      # pickhelper guide: http://www.thomthom.net/thoughts/wp-content/uploads/2013/01/PickHelper-Rev3.2-18-03-2013.pdf

      entity = nil
      transform = nil
      depth = nil

      ph = view.pick_helper(x, y)
      ph.count.times do |i|
        leaf = ph.leaf_at(i)
        next unless leaf.is_a? type

        # ignore Sketchup::Image content
        path = ph.path_at(i)
        next if (path.length >= 2) && path[-2].is_a?(Sketchup::Image)

        if depth.nil? || ph.depth_at(i) < depth
          entity = leaf
          transform = ph.transformation_at(i)
        end
      end

      entity.nil? ? nil : [entity, transform]
    end

    def self.pick_image(view, x, y)
      ph = view.pick_helper(x, y)
      ph.count.times do |i|
        root = ph.element_at(i)
        if root.is_a? Sketchup::Image
          return [root, ph.transformation_at(i)]
        end

      end

      nil
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
