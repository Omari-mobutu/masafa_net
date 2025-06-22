class ApplicationService
  def self.call(*args)
      new(*args).call
  end

  # All service objects inheriting from ApplicationService
  # must implement their own 'call' instance method.
  # It's good practice to add a placeholder or raise an error for subclasses to override.
  def call
    raise NotImplementedError, "Service objects must implement the 'call' instance method."
  end
end
