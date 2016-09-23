require 'yaml'

require "#{File.dirname(__FILE__)}/ruby_array_ext.rb"
require "#{File.dirname(__FILE__)}/result_objects.rb"
require "#{File.dirname(__FILE__)}/setup.rb"

# load results

SYSTEMS = ['o7','b07','b10']

WALLT_FUN_FACTOR = {
    'o7' => 10,
    'b07' => 35,
    'b10' => 22,
}

GP_FN = 'image.gp'

$results = {}

SYSTEMS.each do |system|
  File.open("result_storage_#{system}.dump", "rb") do |f|
    $results[system] = Marshal::load(f)
  end
end

def larger_power_of_two(n)
  p = 1
  p <<= 1 while p <= n
  p
end

# value getter

def get_value(system, value_name, num_versions, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads)
  val_arr = []
  NUM_RUNS.times do |run|
    config = RunConfig.new(num_versions, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads, run)
    result = $results[system][config]
    val_arr << result.send(value_name)
  end
  val_arr.median
end

# configure space

METHOD_NAMES = %w{Same Random Sequential Converging Dynamic}

VALUE_NAMES = {
    'l1_icm' => "Level 1 Instruction Cache Misses",
    'l2_icm' => "Level 2 Instruction Cache Misses",
    'l3_tcm' => "Level 3 Cache Misses",
    'wall_t' => "Normalized Wall Time",
}

FONT = "CMU Serif"

NUM_CHARTS = 4

W = NUM_CHARTS==2 ? 3400 : 6000
H = 1500

LEFT = NUM_CHARTS==2 ? 0.1 : 0.06
RIGHT = NUM_CHARTS==2 ? 0.84 : 0.89

#value = "l1_icm"
value = "l2_icm"
#value = "l3_tcm"
#value = "wall_t"

#num_versions
#code_size
method = 1
#methods = [0,1]#,3,4]
converge_thresh = CONVERGE_THRESH
switch_thresh = SWITCH_THRESH
inner_iterations = 1
#inner_iterations_vec = [1,2,4,8]
#num_threads = 1
#num_threads_vec = [2,8,32,64]
#num_threads_vec = [2,4,8,12]
num_threads_vec = [2,8,16,32]

#system = "o7"
system = "b10"
#system = "b07"

File.open(GP_FN,"w+") do |img_file|

  title = "L1 ICM"

  vals = []

  gp_str = "set term pngcairo size #{W},#{H} font '#{FONT},72'\nset output \"out.png\"\n"

  gp_str += <<EOS
  if (!exists("MP_LEFT"))   MP_LEFT = #{LEFT}
  if (!exists("MP_RIGHT"))  MP_RIGHT = #{RIGHT}
  if (!exists("MP_BOTTOM")) MP_BOTTOM = .15
  if (!exists("MP_TOP"))    MP_TOP = .91
  if (!exists("MP_GAP"))    MP_GAP = 0.01
EOS

  #iteratee = methods
  #iteratee = inner_iterations_vec
  iteratee = num_threads_vec

  gp_str += "set multiplot layout 1,#{iteratee.size} margins screen MP_LEFT, MP_RIGHT, MP_BOTTOM, MP_TOP spacing screen MP_GAP\n\n"

  #methods.each do |method|
  #inner_iterations_vec.each do |inner_iterations|
  num_threads_vec.each do |num_threads|
    #iterator = method
    #iterator = inner_iterations
    iterator = num_threads

    outer_iterations = OUTER_ITERATIONS / inner_iterations

    gp_str += <<EOS

  set title "#{METHOD_NAMES[method]}, it = #{inner_iterations}" font '#{FONT}, 80' offset 0,-1
  #set title "#{METHOD_NAMES[method]}, #threads = #{num_threads}" font '#{FONT}, 80' offset 0,-1
  set palette defined ( 0 1 1 1, 1 0 0 0 )
  set cblabel "#{VALUE_NAMES[value]}" offset 1.0,0,0
  set logscale cb
  set cbtics %%TICKSFACTOR%%
  set format cb "%.#{value == "wall_t" ? "1f" : "0s %c"}"

  set xrange [0.5:#{CODE_SIZES.length-1}.5]
  set xtics (#{CODE_SIZES.each_with_index.map { |s,i| "\"#{s}\" #{i} " }.join(",")}) offset 0,0.5
  set xlabel "Code Size" offset 0,1
  show xlabel
  set yrange [0.5:#{NUM_VERSIONS.length-1}.5]
  set ytics (#{NUM_VERSIONS.each_with_index.map { |s,i| "\"#{s}\" #{i} " }.join(",")}) offset 0.5,0
  set ylabel "Number of Versions" offset 1.6,0
  set tics scale 0

EOS

    if iterator == iteratee[0]
      gp_str += "show ylabel\n"
    else
      gp_str += "unset ytics\n"
      gp_str += "unset ylabel\n"
    end

    if iterator == iteratee.last
      gp_str += "set colorbox user origin #{RIGHT+0.02},.075 size 0.015,.85\n"
    else
      gp_str += "unset colorbox\n"
    end

    gp_str += "$map#{method} << EOD\n"
    NUM_VERSIONS.each do |num_versions|
      CODE_SIZES.each do |code_size|
        val = get_value(system, value, num_versions, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads)
        #val /= (code_size+WALLT_FUN_FACTOR[system]) if value == "wall_t"
        val /= get_value(system, value, 1, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads).to_f if value == "wall_t"
        val *= inner_iterations if value != "wall_t"
        gp_str += sprintf("%16f ", val)
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


  min = vals.min
  min = 1.0 if value == "wall_t"
  max = vals.max
  factor = (Math.log(max.to_f/min) / Math.log(2))**0.4
  factor = 1.1 if value == "wall_t"
  gp_str.gsub!("%%CBRANGE%%", "set cbrange [#{min}:#{max}]")
  gp_str.gsub!("%%TICKSFACTOR%%", "#{factor}")
  img_file.puts(gp_str)
end

`gnuplot #{GP_FN}`


