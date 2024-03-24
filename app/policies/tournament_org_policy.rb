# frozen_string_literal: true

class TournamentOrgPolicy < DirectorPolicy
  class Scope < ScopeBase
    def resolve
      scope.all
    end
  end

  def index?
    sufficient_access?
  end

  def show?
    sufficient_access?
  end

  def update?
    sufficient_access?
  end

  def destroy?
    user.sufficient_access?
  end

  def create?
    sufficient_access?
  end

  private

  def sufficient_access?
    user.superuser?
  end
end
