require 'sketchup.rb'

module Envelop
  module PlanManager
    # This is an example of an observer that watches the application for
    # new models and shows a messagebox.
    class EnvelopAppObserver < Sketchup::AppObserver
      def onNewModel(model)
        puts "Envelop::PlanManager::EnvelopAppObserver.onNewModel: #{model}"

        # Here is where one might attach other observers to the new model.
        Sketchup.active_model.active_view.add_observer(MyViewObserver.new)
      end
      
      def expectsStartupModelNotifications
        return true
      end
    end
    
    # This is an example of an observer that watches tool interactions.
    class MyViewObserver < Sketchup::ViewObserver
      def onViewChanged(view)
        puts "onViewChanged: #{view}"
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
