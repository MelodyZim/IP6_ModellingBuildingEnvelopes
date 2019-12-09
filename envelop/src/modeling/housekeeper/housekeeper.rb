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

    def self.create_house(entity_a)
      # create a new house with the selection as content
      house = Sketchup.active_model.active_entities.add_group(entity_a)

      unless house.manifold?
        # house is not valid
        house.ungroup
        UI.messagebox('Cannot create house group with supplied argument, as the group would not be manifold.')
      else
        @house = house
      end
    end

    def self.add_to_house(entity_a)
      unless @house
        puts "Envelop::Housekeeper.add_to_house: No house yet, thus creating house group with supplied argument."
        create_house(entity_a)
      else

        # group input
        add_group = Sketchup.active_model.active_entities.add_group(entity_a)

        # add operation
        result = @house.outer_shell(add_group)
        if result.nil?
          UI.messagebox('Cannot add supplied argument to house group, as the result would not be manifold.')
          add_group.ungroup
        else
          @house = result
        end
      end
    end

    def self.remove_from_house(entity_a)
      unless @house
        UI.messagebox("No house to remove anything from, not doing anything...");
      else

        # group input
        remove_group = Sketchup.active_model.active_entities.add_group(entity_a)


        # add operation
        result = @house.subtract(house)
        if result.nil?
          UI.messagebox('Cannot remove supplied argument from house group, as the result would not be manifold.')
          remove_group.ungroup
        else
          @house = result
        end
      end
    end

    private

    def self.try_init_with_existing
      @house = search_house # might still be nil, which is fine if new model
      end

    def self.search_house # TODO: probably remove this, as house is saved and &  persisted independend of this attribute
      entities = Sketchup.active_model.active_entities

      entities.each do |entity|
        if entity.is_a? Sketchup::Group
          if entity.get_attribute('house', 'ishouse', default_value = false)
            return entity
          end
        end

        nil
      end
    end

    def self.reload
      remove_instance_variable(:@house) if @house

      try_init_with_existing
    end
    reload
  end
end
