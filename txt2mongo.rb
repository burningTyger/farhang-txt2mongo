#
# txt2mongo
#
# Author:: burningTyger (https://github.com/burningTyger)
# Home:: https://github.com/ckh/farhang
# Copyright:: Copyright (c) 2011 burningTyger
# License:: MIT License
#
# with txt2mongo you can check the integrity of your lexicon text files as
# used in farhang. You pass the file name or wildcard along to check the
# file entries. If you pass in a database name as a second argument txt2mongo
# will store the entries in your mongodb. If you don't get any output it means
# your files are ok. If you get filenames and line numbers it means you need to
# correct them. Usually a ";" is forgotten.
# To check all files you need to put '*.txt' into quotation marks
#
#run like this
#ruby txt2mongo file.txt|'*.txt' [database]
#example
#ruby txt2mongo k.txt test_db
#or
#ruby txt2mongo '*.txt'

if ARGV[1]
  require 'rubygems' if RUBY_VERSION[0,3] == '1.8'
  require 'mongo_mapper'

  MongoMapper.database = ARGV[1]
  
  class Lemma
    include MongoMapper::Document
    key :lemma, String
    key :translation_ids, Array
    many :translations, :in => :translation_ids
    timestamps!
  end
  
  class Translation
    include MongoMapper::Document
    key :source, String
    key :target, String
    timestamps!
  end
  
  Lemma.collection.remove
  Translation.collection.remove
  Lemma.ensure_index(:lemma)
  
  error = {}
  Dir.glob("#{ARGV[0]}").each do |ff|
    File.open(ff, 'r') do |f|
      lemma = nil
      f.each_line do |l|
        source, target = l.split(';')
        begin
          source.strip!
          target.strip!
        rescue
          puts "#{ff.to_s} - #{f.lineno}: #{l}"
        end
        unless source.start_with?('- ')
          lemma = Lemma.create( :lemma => source )
          if target.nil? or target.empty?
            trans = Translation.create( :source => source )
          else
            trans = Translation.create( :source => source, :target => target )
          end
          lemma.translations << trans
          lemma.save
        else
          source.sub!('- ', '')
          trans = Translation.create( :source => source, :target => target )
          lemma.translations << trans
          lemma.save
        end
      end
    end
  end

else
  Dir.glob("#{ARGV[0]}.txt").each do |ff|
    File.open(ff, 'r') do |f|
      f.each_line do |l|
        source, target = l.split(';')
        begin
          source.strip!
          target.strip!
        rescue
          puts "#{ff.to_s} - #{f.lineno}: #{l}"
        end
      end
    end
  end
end
