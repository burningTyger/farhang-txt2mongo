# encoding: UTF-8
if ARGV[0]
  require 'mongo_mapper'
  require 'unicode'
  require 'babosa'

  MongoMapper.database = ARGV[0]

  class Lemma
    include MongoMapper::Document
    key :lemma, String, :unique => true, :required => true, :index => true
    key :slug, String, :unique => true
  end

  Lemma.find_each do |l|
    l.set :slug => l.lemma.to_slug.clean.normalize(:transliterate => :german)
  end
end

