module MediaPlans
  module Exceptions
    class MediaPlanHistory < StandardError; end

    class RestoreMediaPlanVersionError < MediaPlanHistory; end
  end
end
