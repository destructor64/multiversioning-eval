
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

  def initialize(m)
    @num_versions = m[1]
    @code_size = m[2]
    @method = m[3]
    @converge_thresh = m[4]
    @switch_thresh = m[5]
    @inner_iterations = m[6]
    @outer_iterations = m[7]
    @num_threads = m[8]
    @run_id = m[9]
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
    @cpu_t = res[3]
    @wall_t = res[4]
    @l1_icm = res[5]
    @l2_icm = res[6]
    @l3_tcm = res[7]
  end
end
