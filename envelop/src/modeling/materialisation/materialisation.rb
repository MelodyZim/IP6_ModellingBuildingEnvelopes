# frozen_string_literal: true

require 'json'
require 'securerandom'
require_relative '../../vendor/rb/color_math'

module Envelop
  module Materialisation

    DEFAULT_MATERIAL = "default"

    def self.set_tmp_materials(grp)
      materials = Sketchup.active_model.materials

      grp.entities.grep(Sketchup::Face).each do |face|

        if face.material.nil?
          original_name = "noMaterial"
        else
          original_name = face.material.name
        end
        face.set_attribute('tmp_material', 'original_name', original_name)

        material = materials.add(SecureRandom.hex(8))
        face.material = material
      end
    end

    def self.unset_tmp_materials(grp)
      grp.entities.grep(Sketchup::Face).each do |face|

        original_name = face.get_attribute('tmp_material', 'original_name')
        if !original_name.nil?

          if original_name == "noMaterial"
            face.material = nil
          else
            face.material = original_name
          end
          face.delete_attribute("tmp_material")
        end
      end
    end

    def self.delete_material(material_name)
      puts "Envelop::Materialisation.delete_material: deleting material with name #{material_name}..."

      materials = Sketchup.active_model.materials
      materials.remove(materials[material_name]) # TODO: what happens if still in use?
    end

    # TODO: FS: deduplicate add_material and init_materials
    def self.add_material(material_name)
      puts "Envelop::Materialisation.add_material: adding material based on material with name #{material_name}..."

      materials = Sketchup.active_model.materials
      base_material = materials[material_name]
      base_index = base_material.get_attribute('material', 'index')

      # add material
      count = base_material.get_attribute('material', 'count') + 1
      base_id = base_material.get_attribute('material', 'base_id')

      name = "#{base_id} #{count}"
      material = materials.add(name)

      # find true index # TODO: this creates gaps inbetween groups of similarly named materials... but i think this is fine
      true_count = material.name.split(" ").last().to_i
      if true_count != count
        prev_count = true_count

        loop do
          prev_count -= 1

          if prev_count == count - 1
            warn "Envelop::Materialisation.add_material: prev_count == count - 1 while finding true index, which should not happen. keeping base index..."
            break
          end

          prev_name = "#{base_id} #{prev_count}"
          prev_material = materials[prev_name]

          next if prev_material == nil

          new_base_index = prev_material.get_attribute('material', 'index')

          if new_base_index != nil
            base_index  = new_base_index
            break
          end
        end

        count = true_count
      end

      # inc all other index
      materials.each do |aMaterial|
        index = aMaterial.get_attribute('material', 'index')
        if index != nil && index > base_index
          aMaterial.set_attribute('material', 'index', index + 1)
        end
      end

      # finish creating material
      base_color_hsl = base_material.get_attribute('material', 'base_color_hsl')
      color = deviate_color(base_color_hsl)
      material.color = Sketchup::Color.new(color.to_rgb)

      base_name = base_material.get_attribute('material', 'base_name')
      material.set_attribute('material', 'description', "#{base_name} #{count}") # TODO: display this somewhere

      material.set_attribute('material', 'base_id', base_id)
      material.set_attribute('material', 'base_name', base_name)
      material.set_attribute('material', 'count', count)

      material.set_attribute('material', 'base_color_hsl', base_color_hsl)
      material.set_attribute('material', 'color_rgb', color.to_rgb)
      material.set_attribute('material', 'color_hsl_l', color.to_hsl[2] / 100.0)

      material.set_attribute('material', 'index', base_index + 1)

      material.set_attribute('material', 'user_facing', true)

      material.alpha = Envelop::Materialisation::DEFAULT_ALPHA
    end

    def self.init_materials # TODO: save material pallete per machine, independent of default materials and then use those saved materials if any
      materials = Sketchup.active_model.materials

      materials.purge_unused

      material = materials.add(Envelop::Materialisation::DEFAULT_MATERIAL)
      material.color = Sketchup::Color.new(Envelop::Materialisation::COLOR_DEFAULT_MATERIAL_R,Envelop::Materialisation::COLOR_DEFAULT_MATERIAL_G,Envelop::Materialisation::COLOR_DEFAULT_MATERIAL_B)
      material.alpha = Envelop::Materialisation::ALPHA_DEFAULT_MATERIAL

      default_materials_path = html_file = File.join(__dir__, 'default_materials.json')
      default_materials = JSON.parse(File.read(default_materials_path))['default_materials']

      material_index = 1

      default_materials.each do |material_hash|
        count = 1

        base_color = ColorMath.new(material_hash['color']['r'], material_hash['color']['g'], material_hash['color']['b'])
        base_color_hsl = base_color.to_hsl

        while count <= material_hash['count']
          #puts "Envelp::Materialisation.init_materials: #{material_hash['id']} #{count}"

          material = materials.add("#{material_hash['id']} #{count}")

          color = deviate_color(base_color_hsl)
          material.color = Sketchup::Color.new(color.to_rgb)

          material.set_attribute('material', 'description', "#{material_hash['name']} #{count}") # TODO: display this somewhere

          material.set_attribute('material', 'base_id', material_hash['id'])
          material.set_attribute('material', 'base_name', material_hash['name'])
          material.set_attribute('material', 'count', count)

          material.set_attribute('material', 'base_color_hsl', base_color_hsl)
          material.set_attribute('material', 'color_rgb', color.to_rgb)
          material.set_attribute('material', 'color_hsl_l', color.to_hsl[2] / 100.0)

          material.set_attribute('material', 'index', material_index)

          material.set_attribute('material', 'user_facing', true)

          material.alpha = Envelop::Materialisation::DEFAULT_ALPHA

          count += 1
          material_index += 1
        end
      end
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
    def self.deviate_color(color_hsl)
      #puts "Envelop::Materialisation.deviate_color: in_hsl: (#{color_hsl[0]}, #{color_hsl[1]}, #{color_hsl[2]})"

      rand_hue = [-1, 1].sample * rand(Envelop::Materialisation::MIN_HUE_DEVIATION..Envelop::Materialisation::MAX_HUE_DEVIATION) * 360
      rand1 = [-1, 1].sample * rand(Envelop::Materialisation::MIN_DEVIATION..Envelop::Materialisation::MAX_DEVIATION) * 100
      rand2 = [-1, 1].sample * rand(Envelop::Materialisation::MIN_DEVIATION..Envelop::Materialisation::MAX_DEVIATION) * 100

      #puts "Envelop::Materialisation.deviate_color: res_from_hsl: (#{color_hsl[0]}, #{(color_hsl[1] + rand1).clamp(0, 100)}, #{(color_hsl[2] + rand2).clamp(0, 100)})"

      res = ColorMath.from_hsl(
        (color_hsl[0] + rand_hue).clamp(0, 360),
        (color_hsl[1] + rand1).clamp(20, 100),
        (color_hsl[2] + rand2).clamp(20, 90)
      )

      #puts "Envelop::Materialisation.deviate_color: out_hsl: (#{res.to_hsl[0]}, #{res.to_hsl[1]}, #{res.to_hsl[2]})"
      res
    end

    def self.reload
      init_materials
    end
    reload
  end
end
