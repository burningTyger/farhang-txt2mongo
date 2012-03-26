# encoding: UTF-8
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
# run like this
# ruby txt2mongo.rb file.txt|'*.txt' [database]
# example
# ruby txt2mongo.rb k.txt test_db
# or
# ruby txt2mongo.rb '*.txt'
if ARGV[1]
  require 'rubygems' if RUBY_VERSION[0,3] == '1.8'
  require 'mongo_mapper'
  require 'versionable'

  MongoMapper.database = ARGV[1]

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

  Lemma.collection.remove
  Lemma.ensure_index(:lemma)

  def strip_replace(str)
    str.strip.gsub('\;', ';')
  end

  lemma = nil
  Dir.glob("#{ARGV[0]}").each do |ff|
    File.open(ff, 'r') do |f|
      f.each_line do |l|
        next if l.empty?
        # split only if there is no unescaped semicolon (ie. \;)
        # this way you can have translations that include semicolons
        source, target = l.split(/(?<!\\)[;]/)
        begin
          source = strip_replace(source)
          target = strip_replace(target)
        rescue
          puts "#{ff.to_s} - #{f.lineno}: #{l}"
        end
        if !source.start_with?('- ')
          begin
            lemma.save! unless lemma.nil?
          rescue
            puts lemma.lemma
          end
          lemma = Lemma.new( :lemma => source )
          lemma.language = "de"
          unless target.nil? or target.empty?
            trans = Translation.new( :source => source, :target => target )
            lemma.translations << trans
          end
        else
          source.sub!('- ', '')
          trans = Translation.new( :source => source, :target => target )
        	lemma.translations << trans
        end
      end
      lemma.save!
    end
  end

else
  Dir.glob("#{ARGV[0]}").each do |ff|
    File.open(ff, 'r') do |f|
      f.each_line do |l|
        source, target = l.split(/(?<!\\)[;]/)
        begin
          source.strip!
          target.strip!
        rescue
          puts "#{ff.to_s} - #{f.lineno}: #{l}"
        end
        if source.start_with?("-  ") or l.count(";") > 1
          puts "#{ff.to_s} - #{f.lineno}: #{l}"
        end
      end
    end
  end
end

