# frozen_string_literal: true

# Default access policy for app resources.
class ApplicationPolicy
  attr_reader :user, :record

  # @param user [User]
  # @param record
  def initialize(user, record)
    @user = user
    @record = record
  end

  # @return [TrueClass,FalseClass]
  def index?
    user.admin?
  end

  # @return [TrueClass,FalseClass]
  def show?
    user.admin?
  end

  # @return [TrueClass,FalseClass]
  def create?
    user.admin?
  end

  # @return [TrueClass,FalseClass]
  # @see #create?
  def new?
    create?
  end

  # @return [TrueClass,FalseClass]
  def update?
    user.admin?
  end

  # @return [TrueClass,FalseClass]
  # @see #update?
  def edit?
    update?
  end

  # @return [TrueClass,FalseClass]
  def destroy?
    user.admin?
  end

  # Default resource scope.
  class Scope
    # @param user [User]
    # @param scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # @raise [NotImplementedError]
    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
