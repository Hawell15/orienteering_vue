namespace :reprocess do
  desc "Wipe and chronologically replay all competitions of a year: rails 'reprocess:year[2026]'"
  task :year, [ :year ] => :environment do |_t, args|
    year = Integer(args[:year] || Date.current.year)

    YearReprocessor.new(year).call
  end
end
