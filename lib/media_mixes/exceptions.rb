module MediaMixes
  module Exceptions
    class FinalOutputError < StandardError; end

    # Exception raised when you don't meet the general and daily minimum budget
    class FinalOutputMeetsMinimumError < FinalOutputError; end

    # Exception raised when you exceed the original budget for campaign
    class FinalOutputBudgetExceededError < FinalOutputError; end
  end
end
