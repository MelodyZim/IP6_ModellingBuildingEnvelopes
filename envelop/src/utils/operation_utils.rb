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
    #   Envelop::OperationUtils.operation_chain "Operation", lambda  {
    #     puts "First part"
    #     true
    #   }, lambda  {
    #     puts "Second part"
    #     true
    #   }
    #
    def self.operation_chain(name, transparent: false, *lambdas) # TODO: what happens if another operation chain is started within the chain
      Sketchup.active_model.start_operation(name, true, false, transparent)
      puts "Envelop::OperationUtils.operation_chain start_operation \"#{name}\"" unless transparent

      lambdas.each do | lambda |
        next if lambda.call

        puts "Envelop::OperationUtils.operation_chain abort_operation \"#{name}\"" unless transparent
        Sketchup.active_model.abort_operation
        return false
      end

      puts "Envelop::OperationUtils.operation_chain commit_operation \"#{name}\"" unless transparent
      Sketchup.active_model.commit_operation
      true
    end
  end
end
