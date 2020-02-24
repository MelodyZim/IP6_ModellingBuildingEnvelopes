# frozen_string_literal: true

module Envelop
  module OperationUtils

    @is_operation_active = false

    #
    # start an operation and then execute a list of lambdas.
    # if a lambda returns false the operation is aborted and the following lambdas are not executed
    #
    # @return [Boolean] true if the operation was commited, false otherwise
    #
    # @example
    #   Envelop::OperationUtils.operation_chain "Operation", false, lambda  {
    #     puts "First part"
    #     true
    #   }, lambda  {
    #     puts "Second part"
    #     true
    #   }
    #
    # Attention: after 100 transparent operations, one operation will be commited visibly to the Undo-Stack. This is how Sketchup works.
    #
    def self.operation_chain(name, transparent, *lambdas) # TODO: what happens if another operation chain is started within the chain
      if @is_operation_active
        warn "New Operation Chain, but operation is already in progress."
      end

      Sketchup.active_model.start_operation(name, true, false, transparent)
      @is_operation_active = true
      puts "Envelop::OperationUtils.operation_chain start_operation \"#{name}\"" unless transparent

      lambdas.each do | lambda |
        next if lambda.call

        puts "Envelop::OperationUtils.operation_chain abort_operation \"#{name}\"" unless transparent
        Sketchup.active_model.abort_operation
        @is_operation_active = false
        return false
      end

      puts "Envelop::OperationUtils.operation_chain commit_operation \"#{name}\"" unless transparent
      Sketchup.active_model.commit_operation
      @is_operation_active = false
      true
    end
  end
end
