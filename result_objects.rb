
class RunConfig
  attr_accessor :num_versions
  attr_accessor :code_size
  attr_accessor :method
  attr_accessor :converge_thresh
  attr_accessor :switch_thresh
  attr_accessor :inner_iterations
  attr_accessor :outer_iterations
  attr_accessor :num_threads
  attr_accessor :run_id

  def eql?(other)
    num_versions == other.num_versions &&
        code_size == other.code_size &&
        method == other.method &&
        converge_thresh == other.converge_thresh &&
        switch_thresh == other.switch_thresh &&
        inner_iterations == other.inner_iterations &&
        outer_iterations == other.outer_iterations &&
        num_threads == other.num_threads &&
        run_id == other.run_id
  end

  def hash()
    [num_versions,code_size,method,converge_thresh,switch_thresh,inner_iterations,outer_iterations,num_threads,run_id].hash
  end

  def initialize(num_versions,code_size,method,converge_thresh,switch_thresh,inner_iterations,outer_iterations,num_threads,run_id)
    @num_versions = num_versions
    @code_size = code_size
    @method = method
    @converge_thresh = converge_thresh
    @switch_thresh = switch_thresh
    @inner_iterations = inner_iterations
    @outer_iterations = outer_iterations
    @num_threads = num_threads
    @run_id = run_id
  end

  def self.from_match(m)
    RunConfig.new(m[1].to_i, m[2].to_i, m[3].to_i, m[4].to_i, m[5].to_i, m[6].to_i, m[7].to_i, m[8].to_i, m[9].to_i)
  end
end

class RunResult
  attr_accessor :cpu_t
  attr_accessor :wall_t
  attr_accessor :l1_icm
  attr_accessor :l2_icm
  attr_accessor :l3_tcm

  def initialize(txt)
    res = txt[1].split(",")
    @cpu_t = res[3].to_i
    @wall_t = res[4].to_i
    @l1_icm = res[5].to_i
    @l2_icm = res[6].to_i
    @l3_tcm = res[7].to_i
  end
end
