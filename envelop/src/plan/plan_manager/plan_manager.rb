require 'sketchup.rb'

module Envelop
  module PlanManager
    @plans = []
    
    def self.add_plan(plan)
      if plan.is_a? Sketchup::Image
        @plans << plan
      else  
        puts "Envelop::PlanManager.add_plan failed because #{plan} is not an image"
      end
    end
    
    def self.remove_deleted_plans
      @plans = @plans.select { |plan| not plan.deleted?}
    end
    
    def self.get_plans()
      @plans
    end
    
    private
  
    # This is an example of an observer that watches the application for
    # new models and shows a messagebox.
    class EnvelopAppObserver < Sketchup::AppObserver
      def onNewModel(model)
        puts "Envelop::PlanManager::EnvelopAppObserver.onNewModel: #{model}"

        # Here is where one might attach other observers to the new model.
        Sketchup.active_model.active_view.add_observer(PlansVisibilityManager.new)
      end
      
      def expectsStartupModelNotifications
        return true
      end
    end
    
    # This is an example of an observer that watches tool interactions.
    class PlansVisibilityManager < Sketchup::ViewObserver
      def onViewChanged(view)
        # puts "Envelop::PlanManager::PlansVisibilityManager.onViewChanged: #{view.camera.direction}"
        
        # remove deleted plans from plans
        Envelop::PlanManager.remove_deleted_plans
        
        # hide plans that are facing backwards
        Envelop::PlanManager.get_plans.each do |plan|
          plan.hidden = view.camera.direction.dot(plan.normal) > 0
        end
      end
    end

    # Attach the observer
    unless @envelop_app_observer.nil?
      puts "Envelop::PlanManager remove old app observer ..."
      Sketchup.remove_observer(@envelop_app_observer)
    end
    @envelop_app_observer = EnvelopAppObserver.new
    Sketchup.add_observer(@envelop_app_observer)
  end
end
