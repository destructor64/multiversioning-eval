require 'yaml'

require "#{File.dirname(__FILE__)}/ruby_array_ext.rb"
require "#{File.dirname(__FILE__)}/result_objects.rb"
require "#{File.dirname(__FILE__)}/setup.rb"

# load results

STORAGE_FN = 'result_storage_o7.dump'

$results = {}

File.open(STORAGE_FN, "rb") do |f|
  $results = Marshal::load(f)
end

def larger_power_of_two(n)
  p = 1
  p <<= 1 while p <= n
  p
end

# value getter

def get_value(value_name, num_versions, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads)
  val_arr = []
  NUM_RUNS.times do |run|
    result = $results[RunConfig.new(num_versions, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads, run)]
    val_arr << result.send(value_name)
  end
  val_arr.median
end

# configure space

METHOD_NAMES = %w{Same Random Sequential Converging Dynamic}

VALUE_NAMES = {
    'l1_icm' => "Level 1 Instruction Cache Misses",
    'wall_t' => "Normalized Wall Time (ns)",
}

FONT = "CMU Serif"

value = "l1_icm"
#value = "wall_t"

#num_versions
#code_size
#method = 1
methods = [0,1,3,4]
converge_thresh = CONVERGE_THRESH
switch_thresh = SWITCH_THRESH
inner_iterations = 1
outer_iterations = OUTER_ITERATIONS / inner_iterations
num_threads = 1

File.open("image.gp","w+") do |img_file|

  title = "L1 ICM"

  vals = []

  gp_str = "set term pngcairo size 6000,1500 font '#{FONT},60'\nset output \"out.png\"\n"

  gp_str += <<EOS
  if (!exists("MP_LEFT"))   MP_LEFT = .06
  if (!exists("MP_RIGHT"))  MP_RIGHT = .9
  if (!exists("MP_BOTTOM")) MP_BOTTOM = .13
  if (!exists("MP_TOP"))    MP_TOP = .91
  if (!exists("MP_GAP"))    MP_GAP = 0.01
EOS

  gp_str += "set multiplot layout 1,#{methods.size} margins screen MP_LEFT, MP_RIGHT, MP_BOTTOM, MP_TOP spacing screen MP_GAP\n\n"

  methods.each do |method|

    gp_str += <<EOS

  set title "#{METHOD_NAMES[method]}" font '#{FONT}, 80' offset 0,-1
  set palette defined ( 0 1 1 1, 1 0 0 0 )
  set cblabel "#{VALUE_NAMES[value]}" offset 1.8,0,0
  set logscale cb
  set cbtics 2
  set format cb "%.0s %c"

  set xrange [0.5:#{CODE_SIZES.length-1}.5]
  set xtics (#{CODE_SIZES.each_with_index.map { |s,i| "\"#{s}\" #{i} " }.join(",")}) offset 0,0.4
  set xlabel "Code Size" offset 0,1
  show xlabel
  set yrange [0.5:#{NUM_VERSIONS.length-1}.5]
  set ytics (#{NUM_VERSIONS.each_with_index.map { |s,i| "\"#{s}\" #{i} " }.join(",")}) offset 0.5,0
  set ylabel "Number of Versions" offset 0,0
  set tics scale 0

EOS

    if method == methods[0]
      gp_str += "show ylabel\n"
    else
      gp_str += "unset ytics\n"
      gp_str += "unset ylabel\n"
    end

    if method == methods.last
      gp_str += "set colorbox user origin .92,.075 size 0.015,.85\n"
    else
      gp_str += "unset colorbox\n"
    end

    gp_str += "$map#{method} << EOD\n"
    NUM_VERSIONS.each do |num_versions|
      CODE_SIZES.each do |code_size|
        val = get_value(value, num_versions, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads)
        val /= (code_size+10) if value == "wall_t"
        gp_str += sprintf("%16d ", val)
        vals << val
      end
      gp_str += "\n"
    end
    gp_str += "EOD\n"

    gp_str += <<EOS
  %%CBRANGE%%
  #set size square
  #set view map
  plot '$map#{method}' matrix with image
EOS
  end

  gp_str.gsub!("%%CBRANGE%%", "set cbrange [#{larger_power_of_two(vals.min) >> 1}:#{larger_power_of_two(vals.max)}]")
  img_file.puts(gp_str)
end


