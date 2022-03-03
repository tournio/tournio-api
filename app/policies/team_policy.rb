# frozen_string_literal: true

class TeamPolicy < DirectorPolicy
  class Scope < ScopeBase
    def resolve
      user.superuser? ? scope.all : scope.where(tournament_id: user.tournament_ids)
    end
  end

  def edit?
    sufficient_role?
  end

  def update?
    sufficient_role?
  end

  def show?
    sufficient_role?
  end

  def destroy?
    sufficient_role?
  end

  private

  def sufficient_role?
    user.superuser? || user.director?
  end
end
