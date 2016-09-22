
def first_n_powers_of_two(n)
  (0...n).map { |v| 2**v }
end

NUM_RUNS = 3

OUTER_ITERATIONS = 200000

CONVERGE_THRESH = 1000

SWITCH_THRESH = 100

FUN_ITERATIONS = first_n_powers_of_two(7)

CODE_SIZES = [0,1,5,20,50,100,200,400]

NUM_VERSIONS = first_n_powers_of_two(12)

hostname = `hostname`

instrumentation_types = 'wall_time,cpu_time,PAPI_L1_ICM,PAPI_L2_ICM,PAPI_L3_TCM'
num_threads_to_use = first_n_powers_of_two(7)
affinity_mask = 0.upto(num_threads_to_use.last-1)
if hostname.include?("b07")
  num_threads_to_use = [1,2,4,8,12]
  affinity_mask = 0.upto(num_threads_to_use.last-1)
elsif hostname.include?("b10")
  num_threads_to_use = first_n_powers_of_two(6)
  affinity_mask = (0...4).map { |thread| (0...8).map { |core| core*4+thread }}.flatten
  instrumentation_types = 'wall_time,cpu_time,PAPI_L1_ICM,PAPI_L2_ICM,PAPI_L3_ICH,PAPI_L3_ICA'
end

INSTRUMENTATION_TYPES = instrumentation_types
NUM_THREADS = num_threads_to_use
AFFINITY_MASK = affinity_mask

SCHED_METHODS = [0,1,2,3,4]

