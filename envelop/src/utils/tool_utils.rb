# frozen_string_literal: true

module Envelop
  module ToolUtils
    CURSOR_PENCIL = 632
    CURSOR_PUSHPULL = 639
    CURSOR_PUSHPULL_ADD = 755

    TAP_HOLD_THRESHOLD_MS = 300
    CLICK_DRAG_THRESHOLD_MS = 300

    class AbstractTool
      def initialize(name, phases: nil, cursor_id: nil)
        @name = name
        @phases = phases
        @cursor_id = cursor_id
      end

      def activate
        puts "activating #{@name}..."
        reset_tool # also calls set_status_text
      end

      def deactivate(view)
        puts "deactivating #{@name}..."

        # no need to reset_tool, tool instance will be discarded after this

        view.lock_inference
        view.invalidate # don't call redraw because that also sets status text
      end

      def resume(view)
        # puts "resuming #{@name}..."

        redraw
      end

      def suspend(_view)
        # puts "suspending #{@name}..."
      end

      def onCancel(_reason, _view)

        reset_tool
        redraw
      end

      def draw(view)
        if @ip.display?
          @ip.draw(view)
          view.tooltip = @ip.tooltip
        end
      end

      def getExtents
        bb = Geom::BoundingBox.new
        populateExtents(bb) if defined? populateExtents
        bb
      end

      def onSetCursor
        UI.set_cursor(@cursor_id) unless @cursor_id.nil?
      end

      def onMouseMove(_flags, x, y, view, last_point = nil)
        if last_point.nil?
          @mouse_ip.pick(view, x, y)
        else
          @mouse_ip.pick(view, x, y, Sketchup::InputPoint.new(last_point))
        end

        if @mouse_ip.valid?
          @ip.copy! @mouse_ip
        end

        redraw
      end

      def onUserText(text, _view)
        if text.include?(",") or text.include?(" ")
          distances = text.split(/\s*[, ]\s*/).map { |s| s.empty? ? nil : s.to_l.to_f }
        else
          distances = [text.to_l]
        end

        onUserDistances(distances) if defined? onUserDistances
      rescue ArgumentError
        Sketchup.status_text = 'Invalid length'
      end

      def onKeyDown(key, _repeat, _flags, view)
        if (key == CONSTRAIN_MODIFIER_KEY)
          view.lock_inference(@mouse_ip)
          redraw

        elsif (key == VK_ALT) || (key == VK_COMMAND) || (key == VK_CONTROL) || (key == VK_SHIFT)
          @alternate_mode_key = key
          @alternate_mode_key_down_time = Time.now
          @alternate_mode = !@alternate_mode
          redraw
        end
      end

      def onKeyUp(key, _repeat, _flags, view)
        if (key == CONSTRAIN_MODIFIER_KEY)
          view.lock_inference
          redraw

        elsif key == @alternate_mode_key
          elapsed_ms_since_alternate_mode_key_down = (Time.now - @alternate_mode_key_down_time) * 1000.0
          if elapsed_ms_since_alternate_mode_key_down > TAP_HOLD_THRESHOLD_MS
            @alternate_mode = !@alternate_mode
          end
          @alternate_mode_key_down_time = nil
          @alternate_mode_key = nil
          redraw
        end
      end

      def onLButtonDown(flags, x, y, view)
        if @lbutton_down_time.nil?
          @lbutton_down_time = Time.now
          @dragged = false
        end
      end

      def onLButtonUp(flags, x, y, view)
        if not @lbutton_down_time.nil?
          elapsed_ms_since_lbutton_down = (Time.now - @lbutton_down_time) * 1000.0
          if elapsed_ms_since_lbutton_down > CLICK_DRAG_THRESHOLD_MS
            @dragged = true
          end
          @lbutton_down_time = nil
        end
      end

      private

      def redraw
        set_status_text
        Sketchup.active_model.active_view.invalidate
      end

      def reset_tool
        puts "resetting #{@name}..."

        @phase = @phases.first[1] unless @phases.nil?

        @mouse_ip = Sketchup::InputPoint.new
        @ip = Sketchup::InputPoint.new
        Sketchup.active_model.active_view.lock_inference

        @alternate_mode = false
        @alternate_mode_key = nil
        @alternate_mode_key_down_time = nil

        @lbutton_down_time = nil
        @dragged = false


        set_status_text
      end
    end

    def self.silenced
      prev_stdout = $stdout
      $stdout = StringIO.new

      yield

    ensure
      $stdout = prev_stdout
    end
  end
end
