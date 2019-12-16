# frozen_string_literal: true

require 'json'
require 'securerandom'
require_relative '../../vendor/rb/color_math'

module Envelop
  module Materialisation
    DEFAULT_MATERIAL = 'default'

    # Apply DEFAULT_MATERIAL to all faces without material
    #
    # @param entities [Sketchup::Entities, nil] entities to change material recursively (defaults to Sketchup.active_model.active_entities)
    def self.apply_default_material(entities = nil)      
      if entities.nil?
        entities = Sketchup.active_model.active_entities
      end
    
      entities.grep(Sketchup::Face).each do |face|
        if face.material.nil?
          face.material = DEFAULT_MATERIAL
        end
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
        face.set_attribute('tmp_material', 'original_name', original_name)

        material = materials.add(SecureRandom.hex(8))
        face.material = material
      end
    end

    def self.unset_tmp_materials(grp)
      materials = Sketchup.active_model.materials

      grp.entities.grep(Sketchup::Face).each do |face|
        original_name = face.get_attribute('tmp_material', 'original_name')
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
    end

    def self.init_materials
      Sketchup.active_model.materials.purge_unused

      add_default_material

      custom_materials_path = File.join(__dir__, 'custom_materials.json') # TODO: FS: this is a bad idea - it should be written to some user folder, probalby doesnt even work in zipped extension like this
      if File.exist?(custom_materials_path)
        load_custom_materials
      else
        load_default_materials
      end
    end

    def self.add_material(material_name)
      puts "Envelop::Materialisation.add_material: adding material based on material with name #{material_name}..."

      # get values
      base_material = Sketchup.active_model.materials[material_name]
      base_id = base_material.get_attribute('material', 'base_id')
      base_color_hsl = ColorMath.new(*base_material.get_attribute('material', 'color_rgb')).to_hsl
      count = find_next_count_for_material_id_count(base_id, base_material.get_attribute('material', 'count'))
      index = find_index_for_material_id_count(base_id, count)

      # create
      create_material(base_id, material_name, count, base_color_hsl, index)
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

    #  Methods
    def self.find_next_count_for_material_id_count(id, count)
      materials = Sketchup.active_model.materials

      # find unused name
      next_count = count + 1
      while !materials["#{id} #{next_count}"].nil?
        next_count += 1
      end

      next_count
    end

    def self.find_index_for_material_id_count(id, count)
      # TODO: this creates gaps inbetween groups of similarly named materials... but i think this is fine

      materials = Sketchup.active_model.materials

      # find prev material
      prev_count = count - 1
      while materials["#{id} #{prev_count}"].nil?
        prev_count -= 1

        if prev_count < 1
          warn 'Envelop::Materialisation.find_index_for_material_id_count: prev_count < 1 while finding previous material, which should not happen. Returning base_material.index + 1...'
          return materials["#{id} #{count}"].get_attribute('material', 'index') + 1
        end
      end

      # remember index + 1
      index = materials["#{id} #{prev_count}"].get_attribute('material', 'index') + 1

      # inc all other index
      materials.each do |material|
        aIndex = material.get_attribute('material', 'index')
        if !aIndex.nil? && aIndex >= index
          material.set_attribute('material', 'index', aIndex + 1)
        end
      end

      # return res
      return index
    end

    def self.load_default_materials # TODO: save material pallete per machine, independent of default materials and then use those saved materials if any
      default_materials_path = html_file = File.join(__dir__, 'default_materials.json')
      default_materials = JSON.parse(File.read(default_materials_path))['default_materials']

      material_index = 1

      default_materials.each do |material_hash|
        count = 1

        base_color = ColorMath.new(material_hash['color']['r'], material_hash['color']['g'], material_hash['color']['b'])
        base_color_hsl = base_color.to_hsl

        while count <= material_hash['count']

          create_material(material_hash['id'], material_hash['name'], count, base_color_hsl, material_index)

          count += 1
          material_index += 1
        end
      end
    end

    def self.create_material(id, name, count, base_color_hsl, index, color = deviate_color(base_color_hsl))
      # create
      material = Sketchup.active_model.materials.add("#{id} #{count}")

      # base data
      material.set_attribute('material', 'base_id', id)
      material.set_attribute('material', 'base_name', name)
      material.set_attribute('material', 'count', count)

      # description
      material.set_attribute('material', 'description', "#{name} #{count}") # TODO: display this somewhere

      # color
      material.color = Sketchup::Color.new(color.to_rgb)
      material.set_attribute('material', 'color_rgb', color.to_rgb)
      material.set_attribute('material', 'color_hsl_l', color.to_hsl[2] / 100.0)
      material.alpha = Envelop::Materialisation::DEFAULT_ALPHA

      # sorting index
      material.set_attribute('material', 'index', index)

      # is user_facing
      material.set_attribute('material', 'user_facing', true)

      material
    end

    def self.load_custom_materials
      custom_materials_path = File.join(__dir__, 'custom_materials.json')
      # File.open(custom_materials_path,"w") {|f|
      #   f.write(custom_materials_path)
      # }
    end

    def self.deviate_color(color_hsl)
      # puts "Envelop::Materialisation.deviate_color: in_hsl: (#{color_hsl[0]}, #{color_hsl[1]}, #{color_hsl[2]})"

      rand_hue = [-1, 1].sample * rand(Envelop::Materialisation::MIN_HUE_DEVIATION..Envelop::Materialisation::MAX_HUE_DEVIATION) * 360
      rand1 = [-1, 1].sample * rand(Envelop::Materialisation::MIN_DEVIATION..Envelop::Materialisation::MAX_DEVIATION) * 100
      rand2 = [-1, 1].sample * rand(Envelop::Materialisation::MIN_DEVIATION..Envelop::Materialisation::MAX_DEVIATION) * 100

      # puts "Envelop::Materialisation.deviate_color: res_from_hsl: (#{color_hsl[0]}, #{(color_hsl[1] + rand1).clamp(0, 100)}, #{(color_hsl[2] + rand2).clamp(0, 100)})"

      res = ColorMath.from_hsl(
        (color_hsl[0] + rand_hue).clamp(0, 360),
        (color_hsl[1] + rand1).clamp(20, 100),
        (color_hsl[2] + rand2).clamp(20, 90)
      )

      # puts "Envelop::Materialisation.deviate_color: out_hsl: (#{res.to_hsl[0]}, #{res.to_hsl[1]}, #{res.to_hsl[2]})"
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

    def self.reload
      init_materials
    end
    reload
  end
end
