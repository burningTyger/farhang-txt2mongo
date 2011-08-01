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
  
  MongoMapper.database = ARGV[1]
  
  class Lemma
    include MongoMapper::Document
    key :lemma, String
    key :lemma_vowelized, String
    key :rtl, Boolean
    key :translation_ids, Array
    many :translations, :in => :translation_ids
    timestamps!
  end
  
  class Translation
    include MongoMapper::Document
    key :source, String
    key :target, String
    key :fix, Boolean
    key :lemma_ids, Array
    many :lemmas, :in => :lemma_ids
    timestamps!
  end
  
  Lemma.collection.remove
  Translation.collection.remove
  Lemma.ensure_index(:lemma)
  
  #replace wasla with madda on alif
  def fix_typos(str)
    puts "Wasla to Madda in #{str} fixed" if str.gsub!("\u0671", "\u0622")
  end
  
  #this method removes kasra, fatha and damma from lemma
  def devowelize(str)
    str.delete("\u064B-\u0655")
  end
  
  def strip_replace(str)
    str.strip.gsub('\;', ';')
  end
  
  lemma = nil
  Dir.glob("#{ARGV[0]}").each do |ff|
    File.open(ff, 'r') do |f|
      f.each_line do |l|
        # split only if there is no unescaped semicolon (ie. \;)
        # this way you can have translations that include semicolons
        source, target = l.split(/(?<!\\)[;]/)
        begin
          source = strip_replace(source)
          target = strip_replace(target)
        rescue
          puts "#{ff.to_s} - #{f.lineno}: #{l}"
        end
        unless source.start_with?('- ')
          lemma = Lemma.new( :lemma => source )
          unless target.nil? or target.empty?
            trans = Translation.new( :source => source, :target => target )
            lemma.translations << trans
            trans.lemmas << lemma
#            target_lemmas = target.split('،')
#            target_lemmas.each do |t|
#              t.strip!
#              fix_typos(t)
#              ll = Lemma.new( :lemma_vowelized => t, :lemma => devowelize(t), :rtl => true )
#              tt = Translation.new( :source => t, :target => lemma.lemma )
#              ll.translations << tt
#              ll.save
#            end
          end
        else
          source.sub!('- ', '')
          check = Translation.first(:source => source)
          trans = Translation.new( :source => source, :target => target )                
          if check && check.target == target
          	lemma.translations << check
          	check.lemmas << lemma
          	check.save
          	trans.destroy
          	trans = nil
          elsif check && check.target != target
          	lemma.translations << check
          	lemma.translations << trans
          	check.fix = true
          	trans.fix = true
          	trans.lemmas << lemma
          	check.lemmas << lemma
          	check.save
          	puts "fix"
          else
        	  lemma.translations << trans 
    	      trans.lemmas << lemma 		  	    
          end
        end
        lemma.save unless lemma.nil?
        trans.save unless trans.nil?
      end
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
