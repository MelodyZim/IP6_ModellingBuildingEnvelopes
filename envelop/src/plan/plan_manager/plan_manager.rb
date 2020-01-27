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

    def self.hide_all_plans
      get_plans.each do |plan|
        hide_plan(plan)
      end

      Envelop::ObserverUtils.dettach_view_observer(PlansVisibilityManager)
    end

    def self.unhide_all_plans
      @hidden_plans = []

      update_plans_visibility

      Envelop::ObserverUtils.attach_view_observer(PlansVisibilityManager)
    end

    def self.update_plans_visibility(view = Sketchup.active_model.active_view)
      Envelop::PlanManager.get_plans.each do |plan|
        next if @hidden_plans.include?(plan)

        Envelop::OperationUtils.operation_block('Update plan visibility', transparent: true) do
          plan.hidden = view.camera.direction.dot(plan.normal) > 0
          true
        end
      end
    end

    def self.hide_plan(plan)
      Envelop::OperationUtils.operation_block('Hide plan', transparent: true) do
        plan.hidden = true
        true
      end
      @hidden_plans.push(plan)
    end

    private

    def self.remove_plan(plan)
      @plans.delete(plan)
    end

    class RemovePlanFromManagerUponErase < Sketchup::EntityObserver
      def onEraseEntity(entity)
        unless entity.valid?
          Envelop::PlanManager.remove_plan(entity)
        end
      end
    end

    class PlansVisibilityManager < Sketchup::ViewObserver
      def onViewChanged(view)
        # hide plans that are facing backwards
        Envelop::PlanManager.update_plans_visibility(view)
      end
    end

    def self.reload
      @plans = []
      @hidden_plans = []

      Sketchup.active_model.entities.each do |entity|
        isPlan = entity.get_attribute('Envelop::PlanManager', 'isPlan')
        if !isPlan.nil? && isPlan && entity.is_a?(Sketchup::Image)
          Envelop::PlanManager.add_plan(entity)
        end
      end

      Envelop::ObserverUtils.attach_view_observer(PlansVisibilityManager)
    end
    reload
  end
end
