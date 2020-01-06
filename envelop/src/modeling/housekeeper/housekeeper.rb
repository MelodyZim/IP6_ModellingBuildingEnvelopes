# frozen_string_literal: true

module Envelop
  module Housekeeper
    # TODO: persist and load @house in save

    def self.house_exists?
      !@house.nil?
    end

    def self.get_house
      unless @house
        warn 'Envelop::Housekeeper.get_house: no house variable, returning nil. This will likely cause issues.'
        nil
      end

      @house
    end

    # @param entity_a [Array<Sketchup::Entity>, Sketchup::Group] entities to add, must be manifold
    # @param fail_silently [Boolean]
    def self.create_house(entity_a, fail_silently = false)
      # create a new house with the selection as content
      if entity_a.is_a? Sketchup::Group
        house = entity_a
      else
        house = Sketchup.active_model.active_entities.add_group(entity_a)
      end

      if house.nil?
        if !fail_silently
          UI.messagebox('Cannot create house group with supplied argument, as the group would be nil')
        else
          puts 'Envelop::Housekeeper.create_house: Cannot create house group with supplied argument, as the group would be nil.'
        end
        return
      end

      if house.manifold?
        @house = house
      else
        # house is not valid
        house.explode

        if !fail_silently
          UI.messagebox('Cannot create house group with supplied argument, as the group would not be manifold.')
        else
          puts 'Envelop::Housekeeper.create_house: Cannot create house group with supplied argument, as the group would not be manifold.'
        end
      end
    end

    # @param entity_a [Array<Sketchup::Entity>, Sketchup::Group] entities to add, must be manifold
    # @return [Boolean] true when the operation was successful, false otherwise
    def self.add_to_house(entity_a)
      if @house

        # group input        
        if entity_a.is_a? Sketchup::Group
          add_group = entity_a
        else
          add_group = Sketchup.active_model.active_entities.add_group(entity_a)
        end
        
        Materialisation.set_tmp_materials(add_group)

        # add operation
        result = @house.outer_shell(add_group)  # TODO fix "reference to deleted Group" (@house group is deleted)
        if result.nil?
          UI.messagebox('Cannot add supplied argument to house group, as the result would not be manifold.')
          add_group.explode
          return false
        else
          Materialisation.unset_tmp_materials(result)
          @house = result
          return true
        end
      else
        puts 'Envelop::Housekeeper.add_to_house: No house yet, thus creating house group with supplied argument.'
        create_house(entity_a)
        return true
      end
    end

    # @param entity_a [Array<Sketchup::Entity>, Sketchup::Group] entities to subtract, must be manifold
    # @return [Boolean] true when the operation was successful, false otherwise
    def self.remove_from_house(entity_a)
      if @house

        # group input        
        if entity_a.is_a? Sketchup::Group
          remove_group = entity_a
        else
          remove_group = Sketchup.active_model.active_entities.add_group(entity_a)
        end

        # add operation
        result = remove_group.subtract(@house)
        if result.nil?
          UI.messagebox('Cannot remove supplied argument from house group, as the result would not be manifold.')
          remove_group.explode  # TODO this is not the intended behaviour if entity_a was a group
          return false
        else
          @house = result
          return true
        end
      else
        UI.messagebox('No house to remove anything from, not doing anything...')
        return false
      end
    end

    private

    # TODO: this does not work if mark is still present in the scene
    def self.try_populate_from_model
      model = Sketchup.active_model

      model.definitions.find_all(&:group?).each do |d|
        d.instances.each(&:explode)
      end

      create_house(model.active_entities.to_a, true)
    end

    def self.reload
      remove_instance_variable(:@house) if @house
      try_populate_from_model
    end
    reload
  end
end
