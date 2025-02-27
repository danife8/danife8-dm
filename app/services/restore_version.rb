class RestoreVersion
  def initialize(version_id)
    @version_id = version_id
  end

  def call
    version = PaperTrail::Version.find(version_id)
    raise ActiveRecord::RecordNotFound unless version

    item = version.reify
    return item if item.save

    raise StandardError, "Error trying to restore the version: #{item.errors.full_messages.join(", ")}"
  end

  protected

  attr_accessor :version_id
end
