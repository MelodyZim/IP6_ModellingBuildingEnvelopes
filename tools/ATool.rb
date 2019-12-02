# frozen_string_literal: true

class ATool
  def activate
    @cursor_id = 647
    @counter = 0
    @counter_target = 25
    @mouse_ip = Sketchup::InputPoint.new
    puts 'activating ATool...'
  end

  def deactivate(view)
    puts 'deactivating ATool...'
    view.invalidate
  end

  def resume(view)
    puts 'resuming ATool...'
    view.invalidate
  end

  def suspend(_view)
    puts 'suspending ATool...'
  end

  def onCancel(_reason, _view)
    puts 'canceling ATool...'
  end

  def draw(view)
    @mouse_ip.draw(view) if @mouse_ip.display?
  end

  def onKeyDown(key, repeat, flags, view)
    if key == 13
      @counter_target = -1
    end
  end

  def onSetCursor
    UI.set_cursor(@cursor_id)
  end

  def onMouseMove(_flags, x, y, view)
    @counter += 1
    if  @counter_target != -1 && @counter > @counter_target
        @cursor_id += 1
        @counter = 0
        puts "cursor_id #{@cursor_id}"
    end

    @mouse_ip.pick(view, x, y)
    view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
    view.invalidate
  end
end

Sketchup.active_model.select_tool(ATool.new)
