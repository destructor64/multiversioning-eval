
require 'fileutils'

require "#{File.dirname(__FILE__)}/setup.rb"

GEN_PATH = 'generated'
RES_PATH = 'results'

IRT_OUTFILE_NAME = 'worker_efficiency.log'

IRT_ENV = {
    :IRT_INST_REGION_INSTRUMENTATION => 'enabled',
    :IRT_INST_REGION_INSTRUMENTATION_TYPES => INSTRUMENTATION_TYPES,
}

def apply_irt_env()
  IRT_ENV.each_pair do |k,v|
    ENV[k.to_s] = v
  end
end

Dir.mkdir GEN_PATH unless File.exist?(GEN_PATH)
Dir.mkdir RES_PATH unless File.exist?(RES_PATH)

eval_count = 0
total_evals_required = CODE_SIZES.length * NUM_VERSIONS.length * NUM_RUNS *
    FUN_ITERATIONS.length * NUM_THREADS.length * SCHED_METHODS.length

CODE_SIZES.each do |code_size|
  NUM_VERSIONS.each do |num_versions|
    prog_config = "#{num_versions}_#{code_size}"
    base_fn = "generated_prog_#{prog_config}"
    path_fn = File.join(GEN_PATH, base_fn)

    # create program version if required
    unless File.exist?(path_fn)
      `ruby #{File.dirname(__FILE__)}/multiver.rb #{num_versions} #{code_size} #{path_fn}`
    end

    # perform runs and store data
    NUM_RUNS.times do |run|
      FUN_ITERATIONS.each do |fun_iterations|
        NUM_THREADS.each do |num_threads|
          SCHED_METHODS.each do |sched_method|

            # progress update
            eval_count += 1
            if eval_count%100 == 0
              printf("%10s / %10s runs\n", eval_count, total_evals_required)
            end

            # set up config
            run_config = "#{sched_method} #{CONVERGE_THRESH} #{SWITCH_THRESH} #{fun_iterations} #{OUTER_ITERATIONS/fun_iterations}"
            result_fn = "#{prog_config}_#{run_config.gsub(" ", "_")}_threads#{num_threads}_run#{run}"
            full_result_path = File.join(RES_PATH, result_fn)

            # bail if already complete
            next if File.exist? full_result_path

            # set up environment
            apply_irt_env
            ENV['IRT_NUM_WORKERS'] = num_threads.to_s
            ENV['IRT_AFFINITY_POLICY'] = "IRT_AFFINITY_FIXED:#{AFFINITY_MASK.join(',')}"

            # run
            `#{path_fn} #{run_config}`

            # store the results
            if !File.exist?(IRT_OUTFILE_NAME)
              puts "WARNING: no output generated for #{result_fn}"
            else
              FileUtils.mv(IRT_OUTFILE_NAME, full_result_path)
            end
          end
        end
      end
    end
  end
end

