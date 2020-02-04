# frozen_string_literal: true

class ATool
  def activate
    @cursor_id = 632
    @counter = 0
    @counter_target = 25
    @mouse_ip = Sketchup::InputPoint.new
    puts 'activating ATool...'
  end

  def onCancel(reason, view)
    puts "ATool was canceled for reason ##{reason} in view: #{view}"
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

  def onKeyDown(key, _repeat, _flags, _view)
    @cursor_id -= 1 if key == 63_233
    @cursor_id += 1 if key == 63_232

    puts "onKeyDown: key = #{key}"

    puts 'is VK_ALT' if key == VK_ALT
    puts 'is VK_COMMAND' if key == VK_COMMAND
    puts 'is VK_CONTROL' if key == VK_CONTROL
    puts 'is VK_SHIFT' if key == VK_SHIFT

    puts 'is ALT_MODIFIER_KEY' if key == ALT_MODIFIER_KEY
    puts 'is COPY_MODIFIER_KEY' if key == COPY_MODIFIER_KEY
    puts 'is CONSTRAIN_MODIFIER_KEY' if key == CONSTRAIN_MODIFIER_KEY
  end

  def onSetCursor
    UI.set_cursor(@cursor_id)
  end

  def onMouseMove(_flags, x, y, view)
    @counter += 1
    if @counter_target != -1 && @counter > @counter_target
      @cursor_id += 1
      @counter = 0
      puts "cursor_id #{@cursor_id}"
    end

    @mouse_ip.pick(view, x, y)
    view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
    view.invalidate
  end

  def onLButtonDown(flags, x, y, view)
    puts "onLButtonDown: flags = #{flags}"
    puts "                   x = #{x}"
    puts "                   y = #{y}"
    puts "                view = #{view}"
  end

  def onLButtonUp(flags, x, y, view)
    puts "onLButtonUp: flags = #{flags}"
    puts "                 x = #{x}"
    puts "                 y = #{y}"
    puts "              view = #{view}"
  end
end

def printModel
  puts 'Model Attributes:'
  printDicts(Sketchup.active_model.attribute_dictionaries, 1)
  puts ''
  puts 'Model Hierarchy'
  printHierarchy(Sketchup.active_model.active_entities, 1)
  nil
end

def printHierarchy(grp = Sketchup.active_model.active_entities, indent = 0)
  grp.each do |e|
    if e.is_a? Sketchup::Face
      printIndent(indent)
      puts 'Face Attributes:'
      printDicts(e.attribute_dictionaries, indent + 1)
    elsif e.is_a? Sketchup::Group
      printIndent(indent)
      puts 'Group Attributes:'
      printDicts(e.attribute_dictionaries, indent + 1)

      printIndent(indent)
      puts 'Group Hierarchy:'
      printHierarchy(e.entities, indent + 1)
    end
  end
end

def printDicts(dicts, indent = 0)
  dicts&.each do |d|
    printIndent(indent)
    puts d.name.to_s
    d.each do |k, v|
      printIndent(indent + 1)
      puts "#{k} -> #{v}"
    end
  end
end

def printIndent(indent)
  print '  ' * indent
end

Sketchup.active_model.select_tool(ATool.new)
