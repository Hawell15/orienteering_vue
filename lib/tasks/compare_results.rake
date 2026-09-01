namespace :compare do
  desc "Compare competition results with the old orienteering DB: rails 'compare:results[new_competition_id,old_competition_id]'"
  task :results, [ :new_competition_id, :old_competition_id, :skip_ecn ] => :environment do |_t, args|
    new_id = args[:new_competition_id]
    old_id = args[:old_competition_id]
    skip_ecn = args[:skip_ecn].present?
    abort "Usage: rails 'compare:results[new_competition_id,old_competition_id(,skip_ecn)]'" if new_id.blank? || old_id.blank?

    new_rows = ActiveRecord::Base.connection.select_all(<<~SQL, "new_results", [ new_id.to_i ]).to_a
      SELECT m.runner_id, c.category_name, r.ecn_points, g.group_name, ru.runner_name, ru.surname
      FROM results r
      JOIN groups g       ON g.id = r.group_id AND g.competition_id = $1
      JOIN memberships m  ON m.id = r.membership_id
      JOIN runners ru     ON ru.id = m.runner_id
      JOIN categories c   ON c.id = r.category_id
    SQL

    old_config = ActiveRecord::Base.connection_db_config.configuration_hash.merge(
      database: ENV.fetch("OLD_DB_NAME", "orienteering_#{Rails.env}")
    )
    old_db = PG.connect(
      host: old_config[:host], dbname: old_config[:database],
      user: old_config[:username], password: old_config[:password]
    )
    old_rows = old_db.exec_params(<<~SQL, [ old_id.to_i ]).to_a
      SELECT r.runner_id, c.category_name, r.ecn_points, g.group_name, ru.runner_name, ru.surname
      FROM results r
      JOIN groups g     ON g.id = r.group_id AND g.competition_id = $1
      JOIN runners ru   ON ru.id = r.runner_id
      JOIN categories c ON c.id = r.category_id
    SQL
    old_db.close

    # Runner ids drift between the two DBs, so results are matched by
    # runner name + group; runner_id is carried along for reporting only.
    build_index = ->(rows) do
      rows.each_with_object({}) do |row, index|
        row = row.symbolize_keys
        name = "#{row[:runner_name]} #{row[:surname]}"
        key = [ name.downcase, Group.normalize_group_name(row[:group_name]) ]
        (index[key] ||= []) << {
          runner_id:   row[:runner_id].to_i,
          category:    row[:category_name],
          ecn_points:  row[:ecn_points].to_f,
          group:       row[:group_name],
          runner_name: name
        }
      end
    end

    new_index = build_index.call(new_rows)
    old_index = build_index.call(old_rows)

    puts "new_orient_vue competition #{new_id}: #{new_rows.size} results"
    puts "orienteering   competition #{old_id}: #{old_rows.size} results"
    puts

    describe = ->(row) { "#{row[:group]}  #{row[:runner_name]}  #{row[:category]} / #{row[:ecn_points]}" }

    only_new = new_index.keys - old_index.keys
    only_old = old_index.keys - new_index.keys
    only_new.each do |key|
      new_index[key].each { |row| puts "ONLY IN NEW  runner_id=#{row[:runner_id]}  #{describe.call(row)}" }
    end
    only_old.each do |key|
      old_index[key].each { |row| puts "ONLY IN OLD  runner_id=#{row[:runner_id]}  #{describe.call(row)}" }
    end

    diffs = 0
    (new_index.keys & old_index.keys).sort.each do |key|
      new_list = new_index[key]
      old_list = old_index[key]
      if new_list.size != old_list.size
        diffs += 1
        puts "COUNT DIFF  #{key.last}  #{new_list.first[:runner_name]}  new: #{new_list.size} result(s)  old: #{old_list.size} result(s)"
        next
      end

      new_list.sort_by { |r| [ r[:category], r[:ecn_points] ] }
              .zip(old_list.sort_by { |r| [ r[:category], r[:ecn_points] ] })
              .each do |new_row, old_row|
        ecn_match = skip_ecn || (new_row[:ecn_points] - old_row[:ecn_points]).abs < 1e-9
        next if new_row[:category] == old_row[:category] && ecn_match

        diffs += 1
        puts "DIFF  #{new_row[:group]}  #{new_row[:runner_name]}  " \
             "new(runner_id=#{new_row[:runner_id]}): #{new_row[:category]} / #{new_row[:ecn_points]}  " \
             "old(runner_id=#{old_row[:runner_id]}): #{old_row[:category]} / #{old_row[:ecn_points]}"
      end
    end

    puts
    if diffs.zero? && only_new.empty? && only_old.empty?
      puts "OK: all #{new_rows.size} results match (#{skip_ecn ? 'category only, ecn skipped' : 'category + ecn_points'})"
    else
      puts "#{diffs} differing result(s), #{only_new.size} only in new, #{only_old.size} only in old"
    end
  end
end
