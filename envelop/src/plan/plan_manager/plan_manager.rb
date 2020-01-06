# frozen_string_literal: true

require 'sketchup.rb'

module Envelop
  module PlanManager
    def self.add_plan(plan)
      if plan.is_a? Sketchup::Image
        Envelop::ObserverUtils.attach_entity_observer(RemovePlanFromManagerUponErase, plan)
        plan.set_attribute('Envelop::PlanManager', 'isPlan', true)
        @plans << plan
      else
        puts "Envelop::PlanManager.add_plan failed because #{plan} is not an image"
      end
    end

    def self.get_plans
      @plans
    end

    private

    def self.remove_plan(plan)
      @plans.delete(plan)
    end

    class RemovePlanFromManagerUponErase < Sketchup::EntityObserver
      def onEraseEntity(entity)
        unless entity.valid?
          puts "removing entity"
          #Envelop::PlanManager.remove_plan(entity)
        end
      end
    end

    class PlansVisibilityManager < Sketchup::ViewObserver
      def onViewChanged(view)
        # hide plans that are facing backwards
        # puts Envelop::PlanManager.get_plans.object_id
        # puts Envelop::PlanManager.get_plans

        Envelop::PlanManager.get_plans.each do |plan|
          plan.hidden = view.camera.direction.dot(plan.normal) > 0
        end
      end
    end

    def self.reload
      @plans = []

      Sketchup.active_model.entities.each do |entity|
        isPlan = entity.get_attribute('Envelop::PlanManager', 'isPlan')
        if !isPlan.nil? && isPlan && entity.is_a?(Sketchup::Image)
          Envelop::PlanManager.add_plan(entity)
        end
      end

      # puts Envelop::PlanManager.get_plans.object_id
      # puts Envelop::PlanManager.get_plans

      Envelop::ObserverUtils.attach_view_observer(PlansVisibilityManager)
    end
    reload
  end
end
