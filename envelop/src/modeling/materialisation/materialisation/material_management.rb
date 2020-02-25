require 'json'

module Envelop
  module Materialisation

    def self.manage_materials
      Sketchup.active_model.materials.purge_unused

      ensure_default_material

      if !File.exist?(custom_materials_path)
        init_custom_materials # TODO: write this out
      end

      add_custom_materials

      merge_materials

      hide_conflicting_materials
    end

    def self.save_custom_materials
      materials = user_facing_materials_as_hash_array
      File.open(custom_materials_path, 'w') do |f|
        f.write(JSON.pretty_generate(materials.select { |m| !m['from_model'] }))
      end
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

    def self.add_custom_materials
      materials_array = JSON.parse(File.read(custom_materials_path))
      materials_array.each do |material_hash|
        create_material(material_hash['base_name'], nil,
                        material_hash['name'], nil,
                        material_hash['color_rgb'], material_hash['color_hsl_l'], material_hash['color_alpha'])
      end
    end

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
       materials = Sketchup.active_model.materials
       material = materials.add(name)

       # base data
       material.set_attribute('material', 'base_name', base_name)
       material.set_attribute('material', 'original_name', material.name)

       # color
       material.color = Sketchup::Color.new(color_rgb)
       material.set_attribute('material', 'color_rgb', color_rgb)
       material.set_attribute('material', 'color_hsl_l', color_hsl_l)
       material.alpha = color_alpha

       # other attrs
       material.set_attribute('material', 'user_facing', true)
       material.set_attribute('material', 'from_model', false)
       material.set_attribute('material', 'is_hidden', false)

       material
    end

    def self.merge_materials
      model = Sketchup.active_model
      materials = model.materials

      #  merge identical materials
      materials.each do |material|
        next unless material.get_attribute('material', 'user_facing')
        next unless material.get_attribute('material', 'from_model')

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

    def self.hide_conflicting_materials
      model = Sketchup.active_model
      materials = model.materials

      materials.each do |material|
        material.set_attribute('material', 'is_hidden', false)
      end

      # hide conflicting materials
      materials.each do |material|
          next unless material.get_attribute('material', 'user_facing')
          next unless material.get_attribute('material', 'from_model')

          local_material = materials.select { |m| m.name == material.get_attribute('material', 'original_name') }

          next unless local_material.length == 1
          local_material = local_material.first

          next if local_material.get_attribute('material', 'base_name') == material.get_attribute('material', 'base_name') &&
            local_material.get_attribute('material', 'color_rgb') == material.get_attribute('material', 'color_rgb')&&
            (local_material.alpha - material.alpha).abs <= 0.01 &&
            (local_material.get_attribute('material', 'color_hsl_l') - material.get_attribute('material', 'color_hsl_l')).abs <=  0.01

          local_material.set_attribute('material', 'is_hidden', true)
        end
    end

    class ModelSaveCustomMaterials < Sketchup::ModelObserver
      def onPreSaveModel(model)
        Sketchup.active_model.materials.purge_unused
        
        model.materials.each do |material|
          next unless material.get_attribute('material', 'user_facing')
          next if material.get_attribute('material', 'from_model')

          material.set_attribute('material', 'original_name', material.name)
          material.set_attribute('material', 'from_model', true)
          material.name = material.name + " (Model)"
        end
      end

      def onPostSaveModel(model)
        Envelop::Materialisation.manage_materials
      end
    end

      class OpenModelAppObserver < Sketchup::AppObserver
        def expectsStartupModelNotifications
          return true
        end
        def onActivateModel(model)
          Envelop::Materialisation.manage_materials
        end
        def onOpenModel(model)
          Envelop::Materialisation.manage_materials
        end
      end

    def self.reload
      manage_materials

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
