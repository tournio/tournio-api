# frozen_string_literal: true

class TeamPolicy < DirectorPolicy
  def index?
    sufficient_role?
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
