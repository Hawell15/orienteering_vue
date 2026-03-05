module RussianConversion
  def self.convert_from_russian(name)
    return name unless contains_cyrillic?(name)

    name.gsub!("ья", "ia")
    name.gsub!("ия", "ia")
    name.gsub!("ея", "еa")
    name.gsub!("кс", "x")
    name.gsub!("ки", "chi")
    name.gsub!("ке", "chе")
    name.gsub!("че", "ce")
    name.gsub!("ги", "ghi")
    name.gsub!("ге", "ghe")

    russian_to_romanian =
      {
        "а" => "a",
        "б" => "b",
        "в" => "v",
        "г" => "g",
        "д" => "d",
        "е" => "e",
        "ё" => "io",
        "ж" => "j",
        "з" => "z",
        "и" => "i",
        "й" => "i",
        "к" => "c",
        "л" => "l",
        "м" => "m",
        "н" => "n",
        "о" => "o",
        "п" => "p",
        "р" => "r",
        "с" => "s",
        "т" => "t",
        "у" => "u",
        "ф" => "f",
        "х" => "h",
        "ц" => "ț",
        "ч" => "ci",
        "ш" => "ș",
        "щ" => "ș",
        "ъ" => "i",
        "ы" => "î",
        "ь" => "i",
        "э" => "ă",
        "ю" => "iu",
        "я" => "ia"
      }
    name.chars.map { |char| russian_to_romanian[char] || char }.join
  end

  def self.contains_cyrillic?(str)
    cyrillic_pattern = /\p{Cyrillic}/

    !!(str =~ cyrillic_pattern)
  end
end
