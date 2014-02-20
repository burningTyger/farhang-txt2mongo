# encoding: UTF-8
if ARGV[0]
  require 'mongo_mapper'
  require 'unicode'
  require 'babosa'
  require 'mm-sluggable'

  MongoMapper.database = ARGV[0]

  class Lemma
    include MongoMapper::Document
    plugin MongoMapper::Plugins::Sluggable
    key :lemma, String, :unique => true, :required => true, :index => true
    key :slug, String, :unique => true, :required => true
    sluggable :lemma,
              :method => :slug_hack,
              :callback => :before_validation
  end

  class String
    def slug_hack
      to_slug.clean.normalize(:transliterate => :german)
    end
  end

  Lemma.find_each :batch_size => 500 do |l|
    l.slug = nil
    l.save!
  end
end

