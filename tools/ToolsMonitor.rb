module ToolsMonitor
    def self.start
        if @observer.nil?
            @events = []
            @observer = ToolMonitor.new(@events)
            Sketchup.active_model.tools.add_observer(@observer)
        else
            puts "monitor already running call stop first"
        end
    end

    def self.stop
        if @observer.nil?
            puts "monitor not running!"
        else
            Sketchup.active_model.tools.remove_observer(@observer)
            @observer = nil

            puts "===================="
            puts "Tool Monitor Report"
            puts "--------------------"

            # output
            puts "Tool switches: #{@events.length}"
            puts ""
            aggregate(@events)

            # filter out CameraOrbitTool
            @events.select! { |e| e.tool_id != 10508 } #"CameraOrbitTool"
            remove_duplicates(@events)

            puts "Tool switches without CameraOrbitTool: #{@events.length}"
            puts ""
            aggregate(@events)
        end
        nil
    end

    def self.remove_duplicates(events)
        i = 0
        while i < events.length - 1
            if events[i].tool_id == events[i+1].tool_id
                events.delete_at(i+1)
            else
                i+=1
            end
        end
    end

    def self.aggregate(events)
        aggregation = Struct.new(:time, :count, :ids)
        results = Hash.new { |h, k| h[k] = aggregation.new(0, 0, [])}
        i = 0
        while i < events.length
            if i < events.length - 1
                results[events[i].tool_name].ids << events[i].tool_id
                results[events[i].tool_name].count += 1
                results[events[i].tool_name].time += events[i+1].time - events[i].time
            else
                results[events[i].tool_name].count += 1
            end
            i += 1
        end
        results.each { |k, v| puts "#{k}: #{v.count}, #{v.time}sec"}
        puts "--------------------"
    end

    ChangeEvent = Struct.new(:tool_name, :tool_id, :time)

    class ToolMonitor < Sketchup::ToolsObserver
        def initialize(list)
            @list = list
        end

        def onActiveToolChanged(tools, tool_name, tool_id)
            @list << ChangeEvent.new(tool_name, tool_id, Time.now)
            puts "#{tool_name} (#{tool_id})"
        end
    end
end
