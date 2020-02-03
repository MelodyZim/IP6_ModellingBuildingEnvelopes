# frozen_string_literal: true

module Envelop
  module Housekeeper
    def self.house_exists?
      !@house.nil? && @house.valid?
    end

    def self.get_house
      get_or_find_house
    end

    # @param entity_a [Array<Sketchup::Entity>, Sketchup::Group] entities to add, must be manifold
    # @param fail_silently [Boolean]
    def self.create_house(entity_a)
      # create a new house with the selection as content
      house = if entity_a.is_a? Sketchup::Group
                entity_a
              else
                Sketchup.active_model.active_entities.add_group(entity_a)
              end

      if house.nil?
        puts 'Envelop::Housekeeper.create_house: Cannot create house group with supplied argument, as the group would be nil.'
        return false
      end

      if house.manifold?
        set_new_house(house)
        return true
      else
        puts 'Envelop::Housekeeper.create_house: Cannot create house group with supplied argument, as the group would not be manifold.'
        return false # undoes groups & stuff
      end
    end

    # @param entity_a [Array<Sketchup::Entity>, Sketchup::Group] entities to add, must be manifold
    # @return [Boolean] true when the operation was successful, false otherwise
    def self.add_to_house(entity_a)
      house = get_or_find_house

      if house.nil?
        puts 'No house to add anything to, thus creating house with supplied argument.'
        return create_house(entity_a) # returns true/false
      end

      # group input
      add_group = if entity_a.is_a? Sketchup::Group
                    entity_a
                  else
                    Sketchup.active_model.active_entities.add_group(entity_a)
                  end

      Materialisation.set_tmp_materials(house)
      Materialisation.set_tmp_materials(add_group)

      # add operation
      result = house.outer_shell(add_group)
      if result.nil?
        puts 'Cannot add supplied argument to house group, as the result would not be manifold.'
        return false # undoes tmp material & group
      else
        Materialisation.unset_tmp_materials(result)
        set_new_house(result)
        return true
      end
    end

    # @param entity_a [Array<Sketchup::Entity>, Sketchup::Group] entities to subtract, must be manifold
    # @return [Boolean] true when the operation was successful, false otherwise
    def self.remove_from_house(entity_a)
      house = get_or_find_house

      if house.nil?
        puts 'No house to remove anything from, not doing anything...'
        return false
      end

      # group input
      remove_group = if entity_a.is_a? Sketchup::Group
                       entity_a
                     else
                       Sketchup.active_model.active_entities.add_group(entity_a)
                     end

      Materialisation.set_tmp_materials(house)
      Materialisation.set_tmp_materials(remove_group)

      # remove operation
      result = remove_group.subtract(@house)
      if result.nil?
        puts 'Cannot remove supplied argument from house group, as the result would not be manifold.'
        return false # will undo anything
      else
        Materialisation.unset_tmp_materials(result)
        set_new_house(result)
        return true
      end
    end

    private

    def self.get_or_find_house
      if @house.nil? || !@house.valid?
        puts 'Envelop::Housekeeper.get_or_find_house: @house is nil or not valid, trying to find_house...'
        find_house

        if @house.nil?
          puts 'Envelop::Housekeeper.get_or_find_house: find_house could not find a entity marked as house. Returning nil'
          return nil
        end
      end

      @house
    end

    def self.find_house
      @house = nil

      Sketchup.active_model.entities.each do |entity|
        isHouse = entity.get_attribute('Envelop::Housekeeper', 'isHouse')
        if !isHouse.nil? && isHouse && entity.is_a?(Sketchup::Group)
          puts "Envelop::Housekeeper.find_house: Entity #{entity} is marked as house, remmebering is as such..."
          set_new_house(entity)
        end
      end
    end

    def self.set_new_house(house) # assumes house is valid, a group & manifold
      if !@house.nil? && @house.valid?
        @house.delete_attribute('Envelop::Housekeeper', 'isHouse')
      end

      @house = house

      @house.set_attribute('Envelop::Housekeeper', 'isHouse', true)
    end

    def self.reload
      remove_instance_variable(:@house) if @house

      @house = nil

      find_house
    end

    Envelop::OperationUtils.operation_chain("reload #{File.basename(__FILE__)}", lambda {
      reload
      true
    })
  end
end
