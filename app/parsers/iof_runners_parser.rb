class IofRunnersParser < BaseParser
  require "net/http"

  attr_accessor :hash

  def initialize
    @hash          = {}
    @return_data   = nil
    @return_result = nil
  end

  def convert
    extract_competition_details
    parser(@hash)
  end

  def extract_competition_details
    @hash = {
      groups: extract_groups_details
    }
  end

  def extract_groups_details
    [ results: extract_results ]
  end

  def extract_results
    get_runners_array.map do |runner|
      { runner: extract_runner_details(runner) }
    end
  end

  def add_runners(hash)
    runner = super(hash.except(:sprint_wre_rang, :forest_wre_rang, :sprint_wre_place, :forest_wre_place))
    update_wre_data(runner, hash)
    runner
  end

  def extract_runner_details(runner)
    {
      runner_name:      runner["Last Name"],
      surname:          runner["First Name"],
      yob:              runner["yob"],
      gender:           extract_gender(runner["Gender"]),
      club_id:          Club::DEFAULT_CLUB_ID,
      sprint_wre_rang:  runner["Sprint WRS points"],
      forest_wre_rang:  runner["WRS points"],
      sprint_wre_place: runner["Sprint WRS Position"],
      forest_wre_place: runner["WRS Position"],
      wre_id:           runner["IOF ID"]
    }.compact
  end

  def get_runners_array
    runners = [ "MEN", "WOMEN" ].map do |gender|
      forest_data = get_data("F", gender)

      sprint_data = get_data("FS", gender).each do |data|
        data["Sprint WRS points"] = data.delete("WRS points")
        data["Sprint WRS Position"] = data.delete("WRS Position")
      end

      merge_data(forest_data, sprint_data)
    end.flatten

    existing_ids = Runner.where.not(wre_id: nil).where.not(yob: 0).pluck(:wre_id).to_set
    current_year = Time.current.year

    runners.each do |runner|
      iof_id = runner["IOF ID"].to_i

      next if existing_ids.include?(iof_id)
      age = request_age(iof_id)

      runner["yob"] = age ? (current_year - age) : 0
      sleep 1
    end
  end



  def get_data(type, gender)
    url = "https://ranking.orienteering.org/download.ashx?doctype=rankfile&rank=#{type}&group=#{gender}&todate=#{Time.now.to_date.as_json}&ioc=MDA"
    csv_data  = request_data(url)
    hash_data = csv_data.map(&:to_h)

    hash_data.map do |hash|
      key_array   = hash.keys.first.split("\;")
      value_array = hash.values.first.split("\;")
      Hash[key_array.zip(value_array)].slice("IOF ID", "First Name", "Last Name",  "WRS Position", "WRS points").merge("Gender" => gender)
    end
  end

  def request_data(url)
    csv_content = Net::HTTP.get(URI(url))
    CSV.parse(csv_content, headers: true)
  end

  def request_age(id)
    response = Nokogiri::HTML(Net::HTTP.get(URI("https://ranking.orienteering.org/PersonView?person=#{id}")))
    age_div = response.css("div.align-items-start div").find { |div| div.text.strip.match?(/^Age: \d+$/) }
    return nil unless age_div

    age_div.text[/\d+/].to_i
  end

  def merge_data(forest_data, sprint_data)
    runners_array = forest_data

    sprint_data.each do |data|
      if (detected_hash = runners_array.detect { |runner| runner["IOF ID"] == data["IOF ID"] })
        detected_hash.merge!(data)
      else
        runners_array << data
      end
    end
    runners_array
  end

  def update_wre_data(runner, hash)
    runner.update!(hash.slice(:wre_id, :sprint_wre_rang, :forest_wre_rang, :sprint_wre_place, :forest_wre_place))
  end
end
