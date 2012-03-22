# encoding: UTF-8
if ARGV[0]
  require 'rubygems' if RUBY_VERSION[0,3] == '1.8'
  require 'mongo_mapper'
  require 'versionable'

  MongoMapper.database = ARGV[0]

  class Lemma
    include MongoMapper::Document
    enable_versioning :limit => 0
    key :lemma, String, :unique => true, :required => true
    key :valid, Boolean, :default => true
    key :language, String
    many :translations
    timestamps!
  end

  class Translation
    include MongoMapper::EmbeddedDocument
    key :source, String
    key :target, String
  end

  def convert_umlaut_to_base(input)
    input.sub('ä','a')
         .sub('ö','o')
         .sub('ü','u')
         .sub('ß','ss')
         .sub('Ä','A')
         .sub('Ö','O')
         .sub('Ü','U')
  end

  ("a".."z").each do |letter|
    search_letter = case letter
                    when 'a' then '[aä]'
                    when 'o' then '[oö]'
                    when 'u' then '[uü]'
                    else "[#{letter}]"
                    end
    lemmas = Lemma.all(:lemma => Regexp.new(/^#{search_letter}/i))
    lemmas = lemmas.sort { |a,b| convert_umlaut_to_base(a.lemma).casecmp(convert_umlaut_to_base(b.lemma))}
    puts "Suchbegriff (Regex): #{search_letter} => #{lemmas.count}"
    all_entries = String.new
    lemmas.each do |l|
      entry = String.new
      lemma = "#{l.lemma};\n"
      l.translations.each do |t|
        if t.source == l.lemma
          lemma = "#{t.source}; #{t.target}\n"
        else
          entry << "- #{t.source}; #{t.target}\n"
        end
      end
      all_entries << lemma+entry
    end
    File.open("#{letter}.txt", "w") do |f|
      f.write all_entries
    end
  end
end

