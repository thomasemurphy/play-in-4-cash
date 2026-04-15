class LeaderboardController < ApplicationController
  before_action :require_authentication

  def index
    @tournament = Tournament.current
    return render plain: "No active tournament." if @tournament.nil?

    @games = @tournament.games
      .includes(:home_team, :away_team, :winner_team)
      .order(:conference, :game_type)
      .to_a

    locked_conferences = %w[East West].select { |c| @tournament.locked_for?(c) }
    @any_locked = locked_conferences.any?

    # Only show columns for locked conferences
    @ordered_games = locked_conferences.flat_map do |conf|
      [Game::SEVEN_EIGHT, Game::NINE_TEN, Game::FINAL].map do |type|
        @games.find { |g| g.conference == conf && g.game_type == type }
      end
    end

    visible_game_ids = @ordered_games.map(&:id)
    all_picks = UserPick.where(game_id: visible_game_ids)
      .includes(:picked_winner, :game)

    picks_by_user = all_picks.group_by(&:user_id)

    e9v10  = @ordered_games.find { |g| g.conference == "East" && g.game_type == Game::NINE_TEN }
    e7v8   = @ordered_games.find { |g| g.conference == "East" && g.game_type == Game::SEVEN_EIGHT }
    efinal = @ordered_games.find { |g| g.conference == "East" && g.game_type == Game::FINAL }

    @rows = User.where(id: picks_by_user.keys)
      .order(:email_address)
      .map do |user|
        user_picks = picks_by_user[user.id] || []
        picks_by_game = user_picks.index_by(&:game_id)
        score = user_picks.sum(&:points)
        { user: user, picks: picks_by_game, score: score }
      end
      .sort_by do |r|
        [
          -r[:score],
          r[:picks][e9v10&.id]&.picked_winner&.abbreviation  || "ZZZ",
          r[:picks][e7v8&.id]&.picked_winner&.abbreviation   || "ZZZ",
          r[:picks][efinal&.id]&.picked_winner&.abbreviation || "ZZZ",
        ]
      end
  end
end
