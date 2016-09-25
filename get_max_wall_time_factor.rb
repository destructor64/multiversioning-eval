
require "#{File.dirname(__FILE__)}/ruby_array_ext.rb"
require "#{File.dirname(__FILE__)}/result_objects.rb"
require "#{File.dirname(__FILE__)}/setup.rb"

converge_thresh = CONVERGE_THRESH
switch_thresh = SWITCH_THRESH
inner_iterations = 1

SYSTEMS = ['o7','b07','b10']
investigated_value = "wall_t"

$results = {}

SYSTEMS.each do |system|
  File.open("result_storage_#{system}.dump", "rb") do |f|
    $results[system] = Marshal::load(f)
  end
end

# value getter
def get_value(system, value_name, num_versions, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads)
  val_arr = []
  NUM_RUNS.times do |run|
    config = RunConfig.new(num_versions, code_size, method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads, run)
    result = $results[system][config]
		if not result
			#p "Error getting value for #{system}, #{value_name}, #{num_versions}, #{code_size}, #{method}, #{converge_thresh}, #{switch_thresh}, #{inner_iterations}, #{outer_iterations}, #{num_threads}, #{run}"
			next
		end
    val_arr << result.send(value_name)
  end
	if val_arr.size < NUM_RUNS - 2
		p "Error getting values for #{system}, #{value_name}, #{num_versions}, #{code_size}, #{method}, #{converge_thresh}, #{switch_thresh}, #{inner_iterations}, #{outer_iterations}, #{num_threads}"
	end
  val_arr.median
end


SCHED_METHODS.each do |sched_method|
	puts "Method: #{sched_method}"
	puts " , #{SYSTEMS.join(', ')}"
	NUM_VERSIONS.each do |num_versions|
		print "#{num_versions}"
		SYSTEMS.each do |system|
			num_threads_set = first_n_powers_of_two(7)
			if system.include?("b07")
				num_threads_set = [1,2,4,8,12]
			elsif system.include?("b10")
				num_threads_set = first_n_powers_of_two(6)
			end
			factor = 1.0;
			
			CODE_SIZES.each do |code_size|
				FUN_ITERATIONS.each do |fun_iterations|
					num_threads_set.each do |num_threads|
						
						outer_iterations = OUTER_ITERATIONS / inner_iterations
						val = get_value(system, investigated_value, num_versions, code_size, sched_method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads).to_f
						val /= get_value(system, investigated_value, 1, code_size, sched_method, converge_thresh, switch_thresh, inner_iterations, outer_iterations, num_threads).to_f
						factor = [factor, val].max
						
					end
				end
			end
			
			print ", #{factor}"
		end
		puts
	end
	puts
end

