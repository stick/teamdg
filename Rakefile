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

namespace :load do
  desc 'Add Test Team data'
  task :team do
    puts "Creating event"
    Event.create( name: 'NCTI')
    puts "Creating divisions"
    Group.create( name: 'Moon', event_id: 1 )
    Group.create( name: 'Shine', event_id: 1 )
    puts "Creating team 'Unitty'"
    Team.create( name: 'Unitty', captain: 'Cutt', group_id: 1, event_id: 1 )
    Team.create( name: 'Greenville', captain: 'Cutt', group_id: 1, event_id: 1 )
    Team.create( name: 'Triad', captain: 'Cutt', group_id: 1, event_id: 1 )
    Team.create( name: 'Down East', captain: 'Cutt', group_id: 1, event_id: 1 )
    Team.create( name: 'TCP', captain: 'Cutt', group_id: 2, event_id: 1 )
    Team.create( name: 'C4', captain: 'Cutt', group_id: 2, event_id: 1 )
    Team.create( name: 'Burlington', captain: 'Cutt', group_id: 2, event_id: 1 )
    Team.create( name: 'Cravin Chains', captain: 'Cutt', group_id: 2, event_id: 1 )
    puts "Creating team members"
    Player.create( name: 'BrianSchweberger', team_id: 1, seed: 'open1' )
    Player.create( name: 'Tunny', team_id: 1, seed: 'open2' )
    Player.create( name: 'Barry', team_id: 1, seed: 'open3' )
    Player.create( name: 'McCree', team_id: 1, seed: 'open4' )
    Player.create( name: 'Cutt', team_id: 1, seed: 'master1' )
    Player.create( name: 'Stick', team_id: 1, seed: 'master2' )
    Player.create( name: 'Colin', team_id: 1, seed: 'woman' )
    Player.create( name: 'Sheffy', team_id: 1, seed: 'grandmaster' )
    Player.create( name: 'Cooper', team_id: 1, seed: 'amateur' )
  end
end
