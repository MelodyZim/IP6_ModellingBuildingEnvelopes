# frozen_string_literal: true

module Envelop
  module OperationUtils

    @is_operation_active = false

    def self.start_operation(name)
      if not @is_operation_active
        @is_operation_active = true
        Sketchup.active_model.start_operation(name, true, true)
        return true
      else
        warn 'Envelop::OperationUtils.start_operation: start_operation called but there is already an operation active'
        return false
      end
    end

    def self.commit_operation()
      if @is_operation_active
        @is_operation_active = false
        Sketchup.active_model.commit_operation
        return true
      else
        warn 'Envelop::OperationUtils.commit_operation: commit_operation called but there is no operation active to commit'
        return false
      end
    end

    def self.abort_operation
      if @is_operation_active
        @is_operation_active = false
        Sketchup.active_model.abort_operation
        return true
      else
        warn 'Envelop::OperationUtils.abort_operation: abort_operation called but there is no operation active to abort'
        return false
      end
    end

  end
end
