module Envelop
  module PlanPosition

    # orientation: 0 = Floor, 1 = North, 2 = East, 3 = South, 4 = West
    def self.add_image(image_base64, orientation)
      model = Sketchup.active_model
      model.start_operation('Envelop: Import Plan', true) #TODO: consider separating moving and scaling into two operations, or even adding into a third operation

      image = import_image(image_base64)
      position_image(image, orientation)

      @plan_count = @plan_count + 1

      if @plan_count > 1
        Envelop::PlanPositionTool.activate_plan_position_tool(image)
      else
        # register first plan at the PlanManager
        Envelop::PlanManager.add_plan(image)
      end

      model.commit_operation
    end

    private

    def self.import_image(image_base64)
      image = nil
      Tempfile.create(['plan', '.png']) do |file|
        file.binmode
        file.write(Base64.decode64(image_base64['data:image/png;base64,'.length..-1]))
        file.close

        size = ImageSize.path(file.path)

        point = Geom::Point3d.new(0, 0, 0)

        # reset cam to ensure inital orientation of image
        Envelop::CameraUtils.reset
        image = Sketchup.active_model.entities.add_image(file.path, point, size.width)
        Envelop::CameraUtils.restore
      end
      image
    end

    # TODO: this might not work different north
    # orientation: 0 = Floor, 1 = North, 2 = East, 3 = South, 4 = West
    def self.position_image(image, orientation)
      # floor
      if orientation == 0
        puts('Assuming image is already alligned')
        
        if @floor_image.nil? || @floor_image.deleted?
          @floor_image = image
        end

      # North
      elsif orientation == 1

        # Errect
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.East, 90.degrees)
        image.transform!(trans)

        # translate based on floor image if any set yet
        if @floor_image && !@floor_image.deleted?
          vec = Geom::Vector3d.new(Envelop::Main.North)
          vec.length = @floor_image.bounds.height

          trans = Geom::Transformation.translation(vec)
          image.transform!(trans)
        end

      # East
      elsif orientation == 2
        # Errect
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.East, 90.degrees)
        image.transform!(trans)

        # Rotate
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.Up, -90.degrees)
        image.transform!(trans)

        # Translate back to (0,0,0)
        vec = Geom::Vector3d.new(Envelop::Main.North)
        vec.length = image.bounds.height

        trans = Geom::Transformation.translation(vec)
        image.transform!(trans)

        # translate based on floor image if any set yet
        if @floor_image && !@floor_image.deleted?
          vec = Geom::Vector3d.new(Envelop::Main.East)
          vec.length = @floor_image.bounds.width

          trans = Geom::Transformation.translation(vec)
          image.transform!(trans)
        end

      # South
      elsif orientation == 3

        # Errect
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.East, 90.degrees)
        image.transform!(trans)

        # Rotate
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.Up, -180.degrees)
        image.transform!(trans)

        # Translate back to (0,0,0)
        vec = Geom::Vector3d.new(Envelop::Main.East)
        vec.length = image.bounds.width

        trans = Geom::Transformation.translation(vec)
        image.transform!(trans)

      # West
      elsif orientation == 4
        # Errect
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.East, 90.degrees)
        image.transform!(trans)

        # Rotate
        trans = Geom::Transformation.rotation(Geom::Point3d.new, Envelop::Main.Up, 90.degrees)
        image.transform!(trans)

      else
        warn 'Envelop::ImportPlan.position_image: called with orientation outside of [0-5]. Image positioned as if 0.'
      end
    end

    def self.reload
      if @floor_image
        remove_instance_variable(:@floor_image)
      end
      @plan_count = 0
    end
    reload
  end
end
