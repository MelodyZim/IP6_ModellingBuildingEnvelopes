module Envelop
  module Materialisation

    def self.material_to_hash(material)
      material_hash = {}

      material_hash['name'] = material.name
      material_hash['base_name'] = material.get_attribute('material', 'base_name')
      material_hash['original_name'] = material.get_attribute('material', 'original_name')

      material_hash['from_model'] = material.get_attribute('material', 'from_model')
      material_hash['is_hidden'] = material.get_attribute('material', 'is_hidden')
      material_hash['user_facing'] = material.get_attribute('material', 'user_facing')

      material_hash['color_rgb'] = material.get_attribute('material', 'color_rgb')
      material_hash['color_alpha'] = material.alpha
      material_hash['color_hsl_l'] = material.get_attribute('material', 'color_hsl_l')

      material_hash
    end
  end
end
