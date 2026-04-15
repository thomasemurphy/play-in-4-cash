class PicksController < ApplicationController
  before_action :require_authentication
  before_action :set_tournament

  def index
    if @tournament.locked_for?("East")
      return redirect_to leaderboard_path
    end

    @games = @tournament.games.includes(:home_team, :away_team).to_a

    @picks = Current.user.user_picks
      .where(game_id: @games.map(&:id))
      .index_by(&:game_id)
  end

  def create
    game = Game.find(params[:game_id])

    if @tournament.locked_for?(game.conference)
      render json: { success: false, errors: ["Picks are locked for the #{game.conference}ern Conference"] }, status: :forbidden and return
    end

    pick = Current.user.user_picks.find_or_initialize_by(game: game)
    pick.picked_winner_id = params[:picked_winner_id].presence

    if pick.save
      render json: { success: true, pick: { game_id: game.id, picked_winner_id: pick.picked_winner_id } }
    else
      render json: { success: false, errors: pick.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    pick = Current.user.user_picks.find(params[:id])
    pick.picked_winner_id = params[:picked_winner_id].presence

    if pick.save
      render json: { success: true, pick: { game_id: pick.game_id, picked_winner_id: pick.picked_winner_id } }
    else
      render json: { success: false, errors: pick.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_tournament
    @tournament = Tournament.current
    render plain: "No active tournament found.", status: :not_found if @tournament.nil?
  end
end
