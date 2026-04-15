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

    # For each locked conference, determine which team IDs are impossible in the Final:
    #   - Winner of 7v8 goes straight to playoffs → cannot play in Final
    #   - Loser of 9v10 is eliminated → cannot play in Final
    impossible_final_team_ids_by_conf = locked_conferences.each_with_object({}) do |conf, h|
      seven_eight = @games.find { |g| g.conference == conf && g.game_type == Game::SEVEN_EIGHT }
      nine_ten    = @games.find { |g| g.conference == conf && g.game_type == Game::NINE_TEN }
      ids = []
      ids << seven_eight.winner_team_id if seven_eight&.winner_team_id.present?
      if nine_ten&.winner_team_id.present?
        loser_id = [nine_ten.home_team_id, nine_ten.away_team_id].find { |id| id != nine_ten.winner_team_id }
        ids << loser_id
      end
      h[conf] = ids
    end

    final_games_by_conf = @ordered_games.select { |g| g.game_type == Game::FINAL }.index_by(&:conference)

    e9v10  = @ordered_games.find { |g| g.conference == "East" && g.game_type == Game::NINE_TEN }
    e7v8   = @ordered_games.find { |g| g.conference == "East" && g.game_type == Game::SEVEN_EIGHT }
    efinal = @ordered_games.find { |g| g.conference == "East" && g.game_type == Game::FINAL }

    @rows = User.where(id: picks_by_user.keys)
      .order(:email_address)
      .map do |user|
        user_picks = picks_by_user[user.id] || []
        picks_by_game = user_picks.index_by(&:game_id)
        score = user_picks.sum(&:points)

        # Build set of game_ids where this user's Final pick is now impossible
        impossible_game_ids = final_games_by_conf.each_with_object(Set.new) do |(conf, final_game), set|
          pick = picks_by_game[final_game.id]
          next unless pick&.picked_winner_id.present?
          impossible_ids = impossible_final_team_ids_by_conf[conf] || []
          set << final_game.id if impossible_ids.include?(pick.picked_winner_id)
        end

        max_score = user_picks.sum do |pick|
          if pick.game.winner_team_id.present?
            pick.points
          elsif impossible_game_ids.include?(pick.game_id)
            0
          else
            pick.game.points_value.to_i
          end
        end

        { user: user, picks: picks_by_game, score: score, max_score: max_score, impossible_game_ids: impossible_game_ids }
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
