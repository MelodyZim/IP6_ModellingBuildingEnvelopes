# frozen_string_literal: true

require 'json'
require 'securerandom'
require_relative '../../vendor/rb/color_math'

module Envelop
  module Materialisation
    DEFAULT_MATERIAL = 'default'

    def self.house_contains_default_material(entities = nil)
      entities = Envelop::Housekeeper.get_house.entities if entities.nil? # TODO : this and model_contains_default_material: why active entities and not entities in general

      entities.grep(Sketchup::Face).each do |face|
        if !face.material.nil? && (face.material.name == DEFAULT_MATERIAL)
          return true
        end
      end

      entities.grep(Sketchup::Group).each do |group|
        return true if model_contains_default_material(group.entities)
      end

      false
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

    def self.set_tmp_materials(grp)
      materials = Sketchup.active_model.materials

      grp.entities.grep(Sketchup::Face).each do |face|
        original_name = if face.material.nil?
                          'noMaterial'
                        else
                          face.material.name
                        end

        material = materials.add(SecureRandom.hex(8))
        material.set_attribute('tmp_material', 'original_name', original_name)
        face.material = material
      end
    end

    def self.unset_tmp_materials(grp)
      materials = Sketchup.active_model.materials

      grp.entities.grep(Sketchup::Face).each do |face|
        next if face.material.nil?

        original_name = face.material.get_attribute('tmp_material', 'original_name')

        next if original_name.nil?

        materials.remove(face.material)

        face.material = if original_name == 'noMaterial'
                          nil
                        else
                          original_name
                        end
        face.delete_attribute('tmp_material')
      end
    end

    def self.delete_material(material_name)
      puts "Envelop::Materialisation.delete_material: deleting material with name #{material_name}..."

      materials = Sketchup.active_model.materials
      materials.remove(materials[material_name]) # TODO: what happens if still in use?

      Envelop::Materialisation.save_custom_materials
    end

    def self.init_materials
      Sketchup.active_model.materials.purge_unused

      add_default_material

      if !File.exist?(custom_materials_path)
        init_custom_materials # TODO: write this out
      end

      load_custom_materials
    end

    def self.new_material(material_name)
      puts "Envelop::Materialisation.new_material: new material with name #{material_name}..."

      # create_material
      create_material(material_name, nil, "#{material_name} 1", random_color)

      Envelop::Materialisation.save_custom_materials
    end

    def self.add_material(material_name)
      puts "Envelop::Materialisation.add_material: adding material based on material with name #{material_name}..."

      # get values
      base_material = Sketchup.active_model.materials[material_name]
      base_color_hsl = ColorMath.new(*base_material.get_attribute('material', 'color_rgb')).to_hsl
      base_name = base_material.get_attribute('material', 'base_name')

      # create_material
      create_material(base_name, base_color_hsl)

      Envelop::Materialisation.save_custom_materials
    end

    def self.update_color(material_name, color_rgb_a)
      puts "Envelop::Materialisation.update_color: changing color for material with name #{material_name} to color #{color_rgb_a}..."

      material = Sketchup.active_model.materials[material_name]
      material.color = Sketchup::Color.new(*color_rgb_a)
      material.set_attribute('material', 'color_rgb', color_rgb_a)
      material.set_attribute('material', 'color_hsl_l', ColorMath.new(*color_rgb_a).to_hsl[2] / 100.0)

      Envelop::Materialisation.save_custom_materials
    end

    private

    # Settings
    LAST_MATERIAL_INDEX = 999_999
    DEFAULT_ALPHA = 0.75
    ALPHA_DEFAULT_MATERIAL = 0.5
    COLOR_DEFAULT_MATERIAL_R = 242
    COLOR_DEFAULT_MATERIAL_G = 242
    COLOR_DEFAULT_MATERIAL_B = 242
    MAX_DEVIATION = 0.3 # TODO: consider if these values are optimal
    MIN_DEVIATION = 0.1
    MAX_HUE_DEVIATION = 0.1
    MIN_HUE_DEVIATION = 0.01
    MIN_HSL_S = 20
    MAX_HSL_S = 100
    MIN_HSL_L = 20
    MAX_HSL_L = 90

    #  Methods
    def self.create_material(base_name, base_color_hsl,
                             name = "#{base_name} 1",
                             color = deviate_color(base_color_hsl),
                             color_rgb = color.to_rgb,
                             color_hsl_l = color.to_hsl[2] / 100.0,
                             color_alpha = Envelop::Materialisation::DEFAULT_ALPHA)
      material = Sketchup.active_model.materials[name]
      if !material.nil? &&
        base_name == material.get_attribute('material', 'base_name') &&
        color_rgb == material.get_attribute('material', 'color_rgb') &&
        color_hsl_l == material.get_attribute('material', 'color_hsl_l') &&
        color_alpha == material.alpha

        return material
      end


       # create
       material = Sketchup.active_model.materials.add(name)

       # base data
       material.set_attribute('material', 'base_name', base_name)

       # color
       material.color = Sketchup::Color.new(color_rgb)
       material.set_attribute('material', 'color_rgb', color_rgb)
       material.set_attribute('material', 'color_hsl_l', color_hsl_l)
       material.alpha = color_alpha

       # other attrs
       material.set_attribute('material', 'user_facing', true)
       material.set_attribute('material', 'user_material', true)

       material
    end

    def self.custom_materials_path
      File.join(__dir__, 'custom_materials.json') # TODO: FS: this is a bad idea - it should be written to some user folder, probalby doesnt even work in zipped extension like this
    end

    def self.default_custom_materials_path
      File.join(__dir__, 'default_custom_materials.json') # TODO: FS: this is a bad idea - it should be written to some user folder, probalby doesnt even work in zipped extension like this
    end

    def self.init_custom_materials
      FileUtils.cp(default_custom_materials_path, custom_materials_path)
    end

    def self.user_facing_materials_as_hash_array
      res = []
      Sketchup.active_model.materials.each do |material|
        next unless material.get_attribute('material', 'user_facing')

        material_hash = {}

        material_hash['name'] = material.name

        material_hash['base_name'] = material.get_attribute('material', 'base_name')

        material_hash['color_rgb'] = material.get_attribute('material', 'color_rgb')
        material_hash['color_alpha'] = material.alpha
        material_hash['color_hsl_l'] = material.get_attribute('material', 'color_hsl_l')

        res.push(material_hash)
      end

      res.sort_by { |mat| mat[:name] }

      res
    end

    def self.save_custom_materials
      materials = user_facing_materials_as_hash_array
      # Envelop::OperationUtils.operation_chain "Save Materials in Model", true, lambda {
      #   Sketchup.active_model.set_attribute('Envelop::Materialisation', 'materials', materials)
      # }
      File.open(custom_materials_path, 'w') do |f|
        f.write(JSON.pretty_generate(materials.select { |m| !m['name'].include?(" (Model)") }))
      end
    end

    def self.load_custom_materials
      materials_array = JSON.parse(File.read(custom_materials_path))
      materials_array.each do |material_hash|
        create_material(material_hash['base_name'], nil,
                        material_hash['name'], nil,
                        material_hash['color_rgb'], material_hash['color_hsl_l'], material_hash['color_alpha'])
      end
    end

    def self.random_color()
      res = ColorMath.from_hsl(
        rand(0..360),
        rand(MIN_HSL_S..MAX_HSL_S),
        rand(MIN_HSL_L..MAX_HSL_L)
      )

      res
    end

    def self.deviate_color(color_hsl)
      return nil if color_hsl.nil?

      rand_hue = [-1, 1].sample * rand(MIN_HUE_DEVIATION..MAX_HUE_DEVIATION) * 360
      rand1 = [-1, 1].sample * rand(MIN_DEVIATION..MAX_DEVIATION) * 100
      rand2 = [-1, 1].sample * rand(MIN_DEVIATION..MAX_DEVIATION) * 100

      res = ColorMath.from_hsl(
        (color_hsl[0] + rand_hue).clamp(0, 360),
        (color_hsl[1] + rand1).clamp(MIN_HSL_S, MAX_HSL_S),
        (color_hsl[2] + rand2).clamp(MIN_HSL_L, MAX_HSL_L)
      )

      res
    end

    def self.add_default_material
      materials = Sketchup.active_model.materials
      if materials[Envelop::Materialisation::DEFAULT_MATERIAL].nil?

        material = materials.add(Envelop::Materialisation::DEFAULT_MATERIAL)
        material.color = Sketchup::Color.new(Envelop::Materialisation::COLOR_DEFAULT_MATERIAL_R, Envelop::Materialisation::COLOR_DEFAULT_MATERIAL_G, Envelop::Materialisation::COLOR_DEFAULT_MATERIAL_B)
        material.alpha = Envelop::Materialisation::ALPHA_DEFAULT_MATERIAL
      end
    end

    def self.merge_materials
      model = Sketchup.active_model
      materials = model.materials
      materials.each do |material|
          next unless material.get_attribute('material', 'user_facing')
          next unless material.name.include?(" (Model)")

          local_material = materials.select { |m| m.name == material.get_attribute('material', 'original_name') }

          next unless local_material.length == 1
          local_material = local_material.first

          next unless local_material.get_attribute('material', 'base_name') == material.get_attribute('material', 'base_name')
          next unless local_material.get_attribute('material', 'color_rgb') == material.get_attribute('material', 'color_rgb')
          next unless (local_material.alpha - material.alpha).abs <= 0.01
          next unless (local_material.get_attribute('material', 'color_hsl_l') - material.get_attribute('material', 'color_hsl_l')).abs <=  0.01

          replace_material(material, local_material)
          materials.remove(material)
        end
    end

    def self.replace_material(src_mat, dst_mat, entities = Sketchup.active_model.active_entities)

      entities.grep(Sketchup::Face).each do |face|
          if !face.material.nil? && (face.material == src_mat)
            face.material = dst_mat
          end
      end

      entities.grep(Sketchup::Group).each do |group|
        replace_material(src_mat, dst_mat, group.entities)
      end
    end

    class ModelSaveCustomMaterials < Sketchup::ModelObserver
      def onPreSaveModel(model)
        model.materials.each do |material|
          next unless material.get_attribute('material', 'user_facing')
          next if material.name.include?(" (Model)")

          material.set_attribute('material', 'original_name', material.name)

          material.name = material.name + " (Model)"
        end
      end

      def onPostSaveModel(model)
        Envelop::Materialisation.init_materials
        Envelop::Materialisation.merge_materials
      end
    end

      class OpenModelAppObserver < Sketchup::AppObserver
        def expectsStartupModelNotifications
          return true
        end
        def onActivateModel(model)
          Envelop::Materialisation.merge_materials
        end
        def onOpenModel(model)
          Envelop::Materialisation.merge_materials
        end
      end

    def self.reload
      init_materials
      merge_materials

      Envelop::ObserverUtils.attach_model_observer(ModelSaveCustomMaterials)
    end

    unless file_loaded?(__FILE__)
      Sketchup.add_observer(OpenModelAppObserver.new)
    end

    Envelop::OperationUtils.operation_chain("Reload #{File.basename(__FILE__)}", false, lambda {
      reload
      true
    })
  end
end
