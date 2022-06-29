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
    sufficient_access?
  end

  def update?
    sufficient_access?
  end

  def state_change?
    sufficient_access?
  end

  def clear_test_data?
    sufficient_access?
  end

  def igbots_download?
    sufficient_access?
  end

  def csv_download?
    sufficient_access?
  end

  def update_testing_environment?
    sufficient_access?
  end

  def destroy?
    user.superuser?
  end

  def email_payment_reminders?
    sufficient_access?
  end

  def demo_or_reset?
    user.superuser?
  end

  def stripe_refresh?
    sufficient_access?
  end

  def stripe_status?
    sufficient_access?
  end

  private

  def sufficient_role?
    user.superuser? || user.director?
  end

  def sufficient_access?
    user.superuser? || user.director? && user.tournaments.include?(record)
  end
end
