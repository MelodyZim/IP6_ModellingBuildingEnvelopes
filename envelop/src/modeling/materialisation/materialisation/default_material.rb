module Envelop
  module Materialisation
    DEFAULT_MATERIAL = 'default'
    ALPHA_DEFAULT_MATERIAL = 0.5
    COLOR_DEFAULT_MATERIAL_R = 242
    COLOR_DEFAULT_MATERIAL_G = 242
    COLOR_DEFAULT_MATERIAL_B = 242

    def self.house_contains_default_material(entities = nil)
      entities_contains_material()
    end

    # Apply DEFAULT_MATERIAL to all faces without material
    #
    # @param entities [Sketchup::Entities, nil] entities to change material recursively (defaults to Sketchup.active_model.active_entities)
    def self.apply_default_material(entities = nil)
      entities = Sketchup.active_model.active_entities if entities.nil?

      entities.grep(Sketchup::Face).each do |face|
        face.material = DEFAULT_MATERIAL if face.material.nil?
      end

      entities.grep(Sketchup::Group).each do |group|
        apply_default_material(group.entities)
      end
    end

    def self.entities_contains_material(material_name = DEFAULT_MATERIAL, entities = Envelop::Housekeeper.get_house&.entities)
      if entities.nil?
        return false
      end

      entities.grep(Sketchup::Face).each do |face|
        if !face.material.nil? && (face.material.name == material_name)
          return true
        end
      end

      entities.grep(Sketchup::Group).each do |group|
        return true if entities_contains_material(group.entities)
      end

      false
    end

    def self.ensure_default_material
      materials = Sketchup.active_model.materials
      if materials[DEFAULT_MATERIAL].nil?

        material = materials.add(DEFAULT_MATERIAL)
        material.set_attribute("material", "original_name", "Unset")
        material.color = Sketchup::Color.new(COLOR_DEFAULT_MATERIAL_R, COLOR_DEFAULT_MATERIAL_G, COLOR_DEFAULT_MATERIAL_B)
        material.alpha = ALPHA_DEFAULT_MATERIAL
      end
    end
  end
end
