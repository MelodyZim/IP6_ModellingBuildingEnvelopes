# frozen_string_literal: true

module Envelop
  module Housekeeper
    # TODO: persist and load @house in save

    def self.get_house
      unless @house
        warn 'Envelop::Housekeeper.get_house: no house variable, returning nil. This will likely cause issues.'
        nil
      end

      @house
    end

    def self.set_house(house)
      @house = house
    end

    def self.create_house(entity_a, fail_silently = false)
      # create a new house with the selection as content
      house = Sketchup.active_model.active_entities.add_group(entity_a)

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

    def self.add_to_house(entity_a)
      if @house

        # group input
        add_group = Sketchup.active_model.active_entities.add_group(entity_a)
        Materialisation.set_tmp_materials(add_group)

        # add operation
        result = @house.outer_shell(add_group)
        if result.nil?
          UI.messagebox('Cannot add supplied argument to house group, as the result would not be manifold.')
          add_group.explode
        else
          Materialisation.unset_tmp_materials(result)
          @house = result
        end
      else
        puts 'Envelop::Housekeeper.add_to_house: No house yet, thus creating house group with supplied argument.'
        create_house(entity_a)
      end
    end

    def self.remove_from_house(entity_a)
      if @house

        # group input
        remove_group = Sketchup.active_model.active_entities.add_group(entity_a)

        # add operation
        result = @house.subtract(house)
        if result.nil?
          UI.messagebox('Cannot remove supplied argument from house group, as the result would not be manifold.')
          remove_group.explode
        else
          @house = result
        end
      else
        UI.messagebox('No house to remove anything from, not doing anything...')
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
