# frozen_string_literal: true

require 'sketchup.rb'

module Envelop
  module PlanManager
    # If the angle between a plans flipped normal and the cameras view vector is larger
    # than HIDE_THRESHOLD, the plan gets hidden
    HIDE_THRESHOLD = 75

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

        Envelop::OperationUtils.operation_chain('Update plan visibility', transparent: true, lambda {
          # TODO: calculate angle correct even if camera is set to perspective
          normal_flipped = Geom::Vector3d.new((ORIGIN - plan.normal).to_a)
          plan.hidden = Math.acos(view.camera.direction.dot(normal_flipped)).radians > HIDE_THRESHOLD
          true
        })
      end
    end

    def self.hide_plan(plan)
      Envelop::OperationUtils.operation_chain('Hide plan', transparent: true, lambda {
        plan.hidden = true
        true
      })
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

      model = Sketchup.active_model

      model.entities.each do |entity|
        isPlan = entity.get_attribute('Envelop::PlanManager', 'isPlan')
        if !isPlan.nil? && isPlan && entity.is_a?(Sketchup::Image)
          Envelop::PlanManager.add_plan(entity)
        end
      end

      Envelop::PlanManager.update_plans_visibility(model.active_view)

      Envelop::ObserverUtils.attach_view_observer(PlansVisibilityManager)
    end

    Envelop::OperationUtils.operation_chain("reload #{File.basename(__FILE__)}", lambda {
      reload
      true
    })
  end
end
