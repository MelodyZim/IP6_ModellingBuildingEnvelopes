# frozen_string_literal: true

# from: https://forums.sketchup.com/t/redirect-ruby-console-to-file-s-example/99790

# load in the Ruby console, two methods
# SU_IO.file <symbol,nil> or SU_IO.rc

module SU_IO
class << self

  # maps SU stderr and/or stdout to files(s)
  # won't map from one file to another, must be connected to the console
  # first
  #
  # pass no parameter for both to ruby_all.log
  #
  # or pass:
  #   :both - stderr to ruby_err.log, stdout to ruby_out.log
  #
  #   :err  - stderr to ruby_err.log, stdout stays in Ruby console
  #   :out  - stdout to ruby_out.log, stderr stays in Ruby console
  #
  def file(type = nil)
    path = ENV['RC_PATH'] || ENV['TMPDIR'] || ENV['TEMP'] || ENV['TMP']
    
    unless Dir.exist? path
      UI.messagebox "Need a vaild path for files, see line 22"
      return
    end

    err  = false
    out  = false
      
    if type.nil?
      all = true
    else
      all = false
      arg = type.to_s.downcase.to_sym  # convert to downcase symbol
      case arg
      when :both then out = true ; err = true
      when :err  then err = true
      when :out  then out = true
      else
        UI.messagebox "Bad parameter passed to SU_IO.file!\nUse :all or :err or :out or nothing"
      end
    end

    err_sc = $stderr == SKETCHUP_CONSOLE
    out_sc = $stdout == SKETCHUP_CONSOLE

    if all && (err_sc || out_sc)
      $stderr = STDERR.dup if err_sc
      $stdout = STDOUT.dup if out_sc
      File.open("#{path}/ruby_all.log", mode: 'w+') do |f|
        f.sync = true
        $stderr.reopen(f) if err_sc
        $stdout.reopen(f) if out_sc
      end
    else
      if err && err_sc
        $stderr = STDERR.dup
        File.open("#{path}/ruby_err.log", mode: 'w+') do |f|
          f.sync = true
          $stderr.reopen f
        end
      end
      if out && out_sc
        $stdout = STDOUT.dup
        File.open("#{path}/ruby_out.log", mode: 'w+') do |f|
          f.sync = true
          $stdout.reopen f
        end
      end
    end
    nil
  end

  def rc
    unless $stdout == SKETCHUP_CONSOLE
      $stdout.flush
      $stdout.close
      $stdout = SKETCHUP_CONSOLE
    end
    
    unless $stderr == SKETCHUP_CONSOLE
      $stderr.flush
      $stderr.close
      $stderr = SKETCHUP_CONSOLE
    end
    nil
  end
end
end
