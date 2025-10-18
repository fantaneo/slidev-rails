class ApplicationJob < ActiveJob::Base
  # Retry configuration
  retry_on StandardError, wait: 5.seconds, attempts: 3

  # Discard jobs if they fail after retries
  discard_on ActiveJob::DeserializationError
end
