# frozen_string_literal: true

module Envelop
  module OperationUtils

    @is_operation_active = 0

    #
    # start an operation and then execute a list of lambdas.
    # if a lambda returns false the operation is aborted and the following lambdas are not executed
    # if a lambda inside a nested operation_chain returns false the outer operation_chins are aborted as well
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
    def self.operation_chain(name, transparent, *lambdas)
      if @is_operation_active > 0
        warn "NEW OPERATION CHAIN, BUT OPERATION IS ALREADY IN PROGRESS."
      end

      Sketchup.active_model.start_operation(name, true, false, transparent) if @is_operation_active == 0
      @is_operation_active += 1
      puts "Envelop::OperationUtils.operation_chain start_operation \"#{name}\"" unless transparent

      lambdas.each do | lambda |
        successful = false

        # catch exceptions that could happen by calling the lambda
        begin
          successful = lambda.call
        rescue => exception
          puts exception
          successful = false
        end
        
        # only continue to the next lambda if this one returned true and there is still an operation ongoing
        next if successful && @is_operation_active > 0

        puts "Envelop::OperationUtils.operation_chain abort_operation \"#{name}\"" unless transparent
        Sketchup.active_model.abort_operation
        @is_operation_active = 0
        return false
      end

      puts "Envelop::OperationUtils.operation_chain commit_operation \"#{name}\"" unless transparent
      @is_operation_active -= 1
      Sketchup.active_model.commit_operation if @is_operation_active == 0
      true
    end
  end
end
