class Admin::GamesController < Admin::BaseController
  def index
    @tournament = Tournament.current
    return render plain: "No active tournament." if @tournament.nil?

    @games = @tournament.games
      .includes(:home_team, :away_team, :winner_team)
      .to_a

    @teams_by_conference = @tournament.teams.by_seed.group_by(&:conference)

    @ordered_games = %w[East West].flat_map do |conf|
      [Game::SEVEN_EIGHT, Game::NINE_TEN, Game::FINAL].map do |type|
        @games.find { |g| g.conference == conf && g.game_type == type }
      end
    end
  end

  def update
    @game = Game.find(params[:id])
    winner_id = params[:winner_team_id].presence

    if @game.update(winner_team_id: winner_id)
      redirect_to admin_root_path, notice: "Result saved for #{@game.display_name}."
    else
      redirect_to admin_root_path, alert: "Failed to save result."
    end
  end
end
