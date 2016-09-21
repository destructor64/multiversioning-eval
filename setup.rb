
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

NUM_THREADS = first_n_powers_of_two(7)

SCHED_METHODS = [0,1,2,3,4]

