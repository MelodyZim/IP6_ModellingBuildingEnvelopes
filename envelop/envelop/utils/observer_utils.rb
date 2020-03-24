# frozen_string_literal: true

module Envelop
  module ObserverUtils
    def self.attach_model_observer(model_observer_class)
      attach_generic_observer(@model_observers, model_observer_class, Sketchup.active_model)
    end

    def self.dettach_model_observer(model_observer_class)
      dettach_generic_observer(@model_observers, model_observer_class, Sketchup.active_model)
    end

    def self.attach_view_observer(view_observer_class)
      attach_generic_observer(@view_observers, view_observer_class, Sketchup.active_model.active_view)
    end

    def self.dettach_view_observer(view_observer_class)
      dettach_generic_observer(@view_observers, view_observer_class, Sketchup.active_model.active_view)
    end

    def self.attach_entity_observer(entity_observer_class, entity)
      @entity_observers[entity] = [] if @entity_observers[entity].nil?

      new_observer = entity_observer_class.new

      @entity_observers[entity] << new_observer
      entity.add_observer(new_observer)
    end

    def self.detach_all_observers
      puts 'Envelop::ObserverUtils.detach_all_observers: ...'

      @model_observers&.each_value { |observer| Sketchup.active_model.remove_observer(observer) }
      @view_observers&.each_value { |observer| Sketchup.active_model.active_view.remove_observer(observer) }
      @entity_observers&.each do |entity, observers|
        if entity.valid?
          observers.each { |observer| entity.remove_observer(observer) }
       end
      end

      @model_observers = {}
      @view_observers = {}
      @entity_observers = {}
    end

    private

    def self.dettach_generic_observer(hash, observer_class, dettach_point)
      if hash.key?(observer_class)
        dettach_point.remove_observer(hash[observer_class])
      end
    end

    def self.attach_generic_observer(hash, observer_class, attach_point)
      dettach_generic_observer(hash, observer_class, attach_point)

      hash[observer_class] = observer_class.new
      attach_point.add_observer(hash[observer_class])
    end

    def self.reload
      # detach_all_observers is called in Envelop.reload

      @view_observers = {}
      @model_observers = {}
      @entity_observers = {}
    end

    reload
  end
end
