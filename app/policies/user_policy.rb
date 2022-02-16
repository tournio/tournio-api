# frozen_string_literal: true

class UserPolicy < DirectorPolicy
  class Scope < ScopeBase
    def resolve
      user.superuser? ? scope.all : []
    end
  end

  # Inherited from DirectorPolicy:
  # def destroy?
  #   false
  # end

  #################
  # Must be a superuser to do any of these things.
  #################
  def index?
    superuser_only
  end

  def create?
    superuser_only
  end

  def destroy?
    superuser_only
  end

  #################
  # Must be superuser to do any of these things to a user other than self
  #################
  def show?
    it_is_me || superuser_only
  end

  def edit?
    it_is_me || superuser_only
  end

  def update?
    it_is_me || superuser_only
  end

  ###############

  def superuser_only
    user.superuser?
  end

  def it_is_me
    user.identifier == record.identifier
  end
end
