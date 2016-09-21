require 'yaml'

require "#{File.dirname(__FILE__)}/result_objects.rb"

STORAGE_FN = 'result_storage.dump'

RES_PATH = 'results'

results = {}

Dir[RES_PATH + "/*"].each do |fn|
  m = /(\d+)_(\d+)_(\d+)_(\d+)_(\d+)_(\d+)_(\d+)_threads(\d+)_run(\d+)/.match(fn)
  if m
    c = RunConfig.from_match(m)

    r = RunResult.new(File.readlines(fn))

    results[c] = r
  end
end

puts "Gathered results, dumping..."

File.open(STORAGE_FN, "wb") do |f|
  Marshal::dump(results, f)
end
