require_relative 'app'
require 'rake-progressbar'

desc 'Generate secret session key'
task :session_secret do
  require 'securerandom'
  puts SecureRandom.hex(64)
end

namespace :db do
  desc 'Drop tables from database'
  task :clean do
    puts "Dropping database tables. All data will be removed."
    DB.tables.map{ |t| DB.drop_table?(t, :cascade => true) }
    # Rake::Task['db:drop_enums'].invoke
  end

  desc 'Create schema/initialize tables'
  task :init do
    puts "#{DB.tables.count} tables in schema."
    # Rake::Task['db:create_enums'].invoke
    # so fragile, adding new table requires adding here
    # because we have to load them in the right orders
    # [ :player, :score, :round, :total, :teetime, :layout, :projected, :product, :scorelink, :volunteer, :playoff ].each do |f|
    Dir.glob("./models/*.rb").each do |f|
      puts "Loading: #{f}"
      load(f, true)
      #load("./models/#{f}.rb", true)
    end
    puts "#{DB.tables.count} tables in schema."
  end

  desc 'reset database state to zero: drop and init'
  task :reset do
    Rake::Task['db:clean'].invoke
    Rake::Task['db:init'].invoke
  end

  desc 'create enum types in database'
  task :create_enums do
    DB.create_enum(:stage_type, %w'single_stage two_stage')
    DB.create_enum(:format, %w'single-round-robin double-round-robin single-elimination double-elimination')
  end

  desc 'drop enum types from database'
  task :drop_enums do
    DB.drop_enum(:stage_type, :if_exists => true, :cascade => true)
    DB.drop_enum(:format, :if_exists => true, :cascade => true)
  end
end

namespace :sim do
  desc 'reset games to unplayed'
  task :reset do
    puts "Resetting matches"
    match_bar = RakeProgressbar.new(Event.first.matches.count)
    Event.first.matches.each do |m|
      m.team_a_wins = 0
      m.team_a_losses = 0
      m.team_a_ties = 0
      m.no_decisions = 0
      m.save
      match_bar.inc
    end
    match_bar.finished

    puts "Resetting games"
    games_bar = RakeProgressbar.new(Event.first.games.count)
    Event.first.games.each do |g|
      g.completed = false
      g.winner_id = nil
      g.tie = nil
      g.save
      games_bar.inc
    end
    games_bar.finished
  end

  desc 'simulate games (event.first)'
  task :games, [ :match ] do |t, args|
    event = Event[ENV['event']] or Event.first
    match_count = event.matches_dataset.where(match_num: args[:match]).count
    puts "simulating games for match #{args[:match]}"
    puts "match_count: #{match_count}"
    progress = RakeProgressbar.new(match_count)
    event.matches_dataset.where(match_num: args[:match]).each do |match|
      match.games.each do |g|
        if rand(1..10) < 3
          g.tie = 1
        else
          g.winner_id = g.players.shuffle.first.id
          game_scores = [ [1,0], [2,0], [2,1], [3,2], [3,1], [4,3], [4,2], [5,4], [5,3], [6,4] ]
          r = game_scores.shuffle.first
          g.holes_up = r.shift
          g.holes_remaining = r.shift
        end
        g.completed = true
        g.save
      end
      progress.inc
    end
    progress.finished
  end

  desc 'set games completed'
  task :completed, [ :percent ] do |t, args|
    num_games = Event.first.games.count.to_f
    complete_games = num_games * (args[:percent].to_f / 100)
    puts "num_games: #{num_games}"
    puts "complete_games: #{complete_games}"
    Event.first.games_dataset.each_with_index do |g, i|
      if i < complete_games.round
        g.completed = true
      else
        g.completed = false
      end
      g.save
    end
  end
end

namespace :load do
  desc 'Add Test Team data'
  task :ncti do
    puts "Creating event"
    e = Event.create( name: 'NCTI', team_seeds: %w(open1 open2 open3 open4 master1 master2 grandmaster women amateur), startdate: '05/05/2015', enddate: '05/06/2015' )
    puts "Creating divisions"
    g1 = e.add_group(name: 'Moon')
    g2 = e.add_group(name: 'Shine')
    puts "Creating teams"
    e.add_team( name: 'Unitty', captain: 'Cutt').add_to_group(g1)
    e.add_team( name: 'GVDG', captain: 'Max').add_to_group(g1)
    e.add_team( name: 'Triad', captain: 'Phil').add_to_group(g1)
    e.add_team( name: 'Down East', captain: 'DG').add_to_group(g1)
    e.add_team( name: 'TCP', captain: 'Garland').add_to_group(g2)
    e.add_team( name: 'C4', captain: 'JayPo').add_to_group(g2)
    e.add_team( name: 'Burlington', captain: 'McCoy').add_to_group(g2)
    e.add_team( name: 'Craven Chains', captain: 'KG').add_to_group(g2)
  end
end
