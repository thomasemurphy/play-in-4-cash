class Admin::PicksController < Admin::BaseController
  def index
    @tournament = Tournament.current
    return render plain: "No active tournament." if @tournament.nil?

    @games = @tournament.games.includes(:home_team, :away_team).to_a
    @ordered_games = %w[East West].flat_map do |conf|
      [Game::SEVEN_EIGHT, Game::NINE_TEN, Game::FINAL].map do |type|
        @games.find { |g| g.conference == conf && g.game_type == type }
      end
    end

    @teams_by_conference = @tournament.teams.by_seed.group_by(&:conference)

    all_picks = UserPick.where(game_id: @games.map(&:id))
    picks_by_user = all_picks.group_by(&:user_id)

    @users = User.order(:email_address).map do |user|
      { user: user, picks: (picks_by_user[user.id] || []).index_by(&:game_id) }
    end
  end

  def upsert
    @tournament = Tournament.current
    user = User.find(params[:user_id])
    games = @tournament.games.to_a

    params[:picks].each do |game_id, winner_id|
      game = games.find { |g| g.id == game_id.to_i }
      next unless game

      pick = UserPick.find_or_initialize_by(user: user, game: game)
      pick.picked_winner_id = winner_id.presence
      pick.save!
    end

    redirect_to admin_picks_path, notice: "Picks updated for #{user.display_name_or_email}."
  end
end
