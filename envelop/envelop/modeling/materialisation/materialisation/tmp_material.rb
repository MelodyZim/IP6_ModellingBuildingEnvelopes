require 'securerandom'

module Envelop
  module Materialisation
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
  end
end
