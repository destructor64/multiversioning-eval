
require 'ruby_array_ext.rb'

load_per_fun = ARGV.size > 0 ? ARGV[0].to_i : 10

test_sizes = [400, 600, 800, 1000, 2000]
bin_sizes = []

test_sizes.each do |v|
	`ruby multiver.rb #{v} #{load_per_fun}`
	bin_sizes << [v, File.stat("out").size]
end

results = []

bin_sizes.each_cons(2) do |a,b|
	version_diff = (b[0] - a[0]).abs
	size_diff = (b[1] - a[1]).abs
	results << size_diff / version_diff.to_f
end

puts results.mean
puts results.standard_deviation
