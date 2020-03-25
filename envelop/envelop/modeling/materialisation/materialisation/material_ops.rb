# frozen_string_literal: true

module Envelop
  module Materialisation
    def self.delete_material(material_name)
      puts "Envelop::Materialisation.delete_material: deleting material with name #{material_name}..."

      Envelop::OperationUtils.operation_chain('Delete Material', false, lambda {

        materials = Sketchup.active_model.materials
        material = materials[material_name]

        unless material.nil?
          if entities_contains_material(material_name)
            result = UI.messagebox('The model contains surfaces with the material you are about to delete. Do you want to continue?', MB_YESNO)
            return if result == IDNO

            replace_material(material, materials[DEFAULT_MATERIAL])
          end

          materials.remove(material)

          Envelop::Materialisation.save_custom_materials

          manage_materials
        end

        true # commit operation
      })
    end

    def self.new_material(material_name)
      puts "Envelop::Materialisation.new_material: new material with name #{material_name}..."

      Envelop::OperationUtils.operation_chain('New Material', false, lambda {

        # create_material
        create_material(material_name, nil, "#{material_name} 1", random_color)

        Envelop::Materialisation.save_custom_materials

        true # commit operation
      })
    end

    def self.add_material(material_name)
      puts "Envelop::Materialisation.add_material: adding material based on material with name #{material_name}..."

      Envelop::OperationUtils.operation_chain('Add Material', false, lambda {

        # get values
        base_material = Sketchup.active_model.materials[material_name]
        base_color_hsl = ColorMath.new(*base_material.get_attribute('material', 'color_rgb')).to_hsl
        base_name = base_material.get_attribute('material', 'base_name')

        # create_material
        material = create_material(base_name, base_color_hsl)
        hide_conflicting_materials
        while material.get_attribute('material', 'is_hidden')
          puts "Envelop::Materialisation.add_material: Creating another material as the previous is hidden."
          material = create_material(base_name, base_color_hsl)
          hide_conflicting_materials
        end

        Envelop::Materialisation.save_custom_materials

        true # commit operation
      })
    end

    def self.update_color(material_name, color_rgb_a)
      puts "Envelop::Materialisation.update_color: changing color for material with name #{material_name} to color #{color_rgb_a}..."

      Envelop::OperationUtils.operation_chain('Change Material Color', false, lambda {

        material = Sketchup.active_model.materials[material_name]
        material.color = Sketchup::Color.new(*color_rgb_a)
        material.set_attribute('material', 'color_rgb', color_rgb_a)
        material.set_attribute('material', 'color_hsl_l', ColorMath.new(*color_rgb_a).to_hsl[2] / 100.0)

        Envelop::Materialisation.save_custom_materials

        true # commit operation
      })
    end

    def self.user_facing_materials_as_hash_array
      res = []
      Sketchup.active_model.materials.each do |material|
        next unless material.get_attribute('material', 'user_facing')

        res.push(material_to_hash(material))
      end

      res.sort_by { |mat| mat[:name] }

      res
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
  end
end
