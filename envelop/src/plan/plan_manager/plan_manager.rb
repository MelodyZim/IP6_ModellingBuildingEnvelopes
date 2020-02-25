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
    end

    def self.unhide_all_plans
      @plans.each do |plan|
        plan.hidden = false
      end
    end

    def self.hide_plan(plan)
      Envelop::OperationUtils.operation_chain('Hide Plan', true, lambda {
        plan.hidden = true
        true
      })
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

    def self.reload
      @plans = []

      # search the model for Images marked as plans
      Sketchup.active_model.entities.each do |entity|
        isPlan = entity.get_attribute('Envelop::PlanManager', 'isPlan')
        if !isPlan.nil? && isPlan && entity.is_a?(Sketchup::Image)
          Envelop::PlanManager.add_plan(entity)
        end
      end
    end

    Envelop::OperationUtils.operation_chain("Reload #{File.basename(__FILE__)}", false, lambda {
      reload
      true
    })
  end
end
