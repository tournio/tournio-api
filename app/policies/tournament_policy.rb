# frozen_string_literal: true

class TournamentPolicy < DirectorPolicy
  class Scope < ScopeBase
    def resolve
      user.superuser? ? scope.all : scope.where(id: user.tournament_ids)
    end
  end

  def index?
    sufficient_role?
  end

  def show?
    sufficient_role?
  end

  def state_change?
    sufficient_role?
  end

  def clear_test_data?
    sufficient_role?
  end

  def igbots_download?
    sufficient_role?
  end

  def csv_download?
    sufficient_role?
  end

  def update_testing_environment?
    sufficient_role?
  end

  private

  def sufficient_role?
    user.superuser? || user.director?
  end
end
