# frozen_string_literal: true

class FreeEntryPolicy < DirectorPolicy
  def create?
    sufficient_role?
  end

  def confirm?
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
