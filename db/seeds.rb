# 2025-26 NBA Play-In Tournament seed data
# Update team names/abbreviations each year to reflect current standings

tournament = Tournament.find_or_create_by!(year: 2026) do |t|
  t.active = true
end

# East Conference play-in teams (seeds 7-10)
east_teams = [
  { name: "Philadelphia 76ers", abbreviation: "PHI", conference: "East", seed: 7 },
  { name: "Orlando Magic",      abbreviation: "ORL", conference: "East", seed: 8 },
  { name: "Charlotte Hornets",  abbreviation: "CHA", conference: "East", seed: 9 },
  { name: "Miami Heat",         abbreviation: "MIA", conference: "East", seed: 10 },
]

# West Conference play-in teams (seeds 7-10)
west_teams = [
  { name: "Phoenix Suns",        abbreviation: "PHX", conference: "West", seed: 7 },
  { name: "Portland Trail Blazers", abbreviation: "POR", conference: "West", seed: 8 },
  { name: "LA Clippers",         abbreviation: "LAC", conference: "West", seed: 9 },
  { name: "Golden State Warriors", abbreviation: "GSW", conference: "West", seed: 10 },
]

all_teams_data = east_teams + west_teams
all_teams_data.each do |attrs|
  team = Team.find_or_initialize_by(tournament: tournament, conference: attrs[:conference], seed: attrs[:seed])
  team.name = attrs[:name]
  team.abbreviation = attrs[:abbreviation]
  team.save!
end

# Create games for each conference
%w[East West].each do |conference|
  teams = tournament.teams.for_conference(conference).by_seed

  seed7  = teams.find_by(seed: 7)
  seed8  = teams.find_by(seed: 8)
  seed9  = teams.find_by(seed: 9)
  seed10 = teams.find_by(seed: 10)

  # Game 1: #7 hosts #8 (home = 7 seed)
  Game.find_or_create_by!(tournament: tournament, conference: conference, game_type: Game::SEVEN_EIGHT) do |g|
    g.home_team = seed7
    g.away_team = seed8
  end

  # Game 2: #9 hosts #10 (home = 9 seed)
  Game.find_or_create_by!(tournament: tournament, conference: conference, game_type: Game::NINE_TEN) do |g|
    g.home_team = seed9
    g.away_team = seed10
  end

  # Game 3 (final): loser of 7v8 hosts winner of 9v10
  # Teams are TBD; use placeholder seeds — we store them as seed8 vs seed9
  # (loser of 7v8 is the lower-seeded loser; winner of 9v10 is TBD)
  # For pick purposes we record "home" as the #8 (likely loser of 7v8 side)
  Game.find_or_create_by!(tournament: tournament, conference: conference, game_type: Game::FINAL) do |g|
    g.home_team = seed8
    g.away_team = seed9
  end
end
