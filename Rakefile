require_relative 'app'

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
  task :reset_games do
    Event.first.games_dataset.each do |g|
      g.completed = false
      g.winner = nil
      g.tie = nil
      g.save
    end
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
