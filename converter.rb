require 'mongo_mapper'

MongoMapper.database = 'testing'

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
Dir.glob('../farhang/*.txt').each do |ff|
  File.open(ff, 'r') do |f|
    lemma = nil
    f.each_line do |l|
      source, target = l.split(';')
      begin
        source.strip!
        target.strip!
      rescue
        error["#{ff.basename}: #{f.lineno}"] = l
      end
      unless source.start_with?('- ')
        lemma = Lemma.create( :lemma => source )
        if target.empty? or target.nil?
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

error.each_pair {|k,v| puts "#{k}: #{v}"}
