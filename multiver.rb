
# environment variables
MULTIVER_CC = 'MULTIVER_CC'
MULTIVER_PAPI_DIR = 'MULTIVER_PAPI_DIR'

pre_str = <<EOS
#include <stdlib.h>
#include <stdio.h>

#define IRT_LIBRARY_MAIN
#include "irt_library.hxx"

extern "C" {
	#include "instrumentation_regions.h"
}

int numLoopIterations = 1;

volatile double noOpt = 0.0;

typedef double (*funType)(int, double, double);
EOS

main_str = <<EOS
volatile int method;
int main(int argc, char** argv) {
	const int method = atoi(argv[1]);
	const int convergeThreshold = atoi(argv[2]);
	const int dynamicSwitchThreshold = atoi(argv[3]);
	numLoopIterations = atoi(argv[4]);
	const int outerLoopIterations = atoi(argv[5]);
	
	irt::merge(irt::parallel([=] {
		irt_inst_region_start(0);
		int convergingSelection = 0;
		int dynamicSelection = 0;
		unsigned int r = irt::thread_num();
		
		double a = 1.0;
		double b =  2.0;
		double sum = 0.0;
		
		for(int i=0; i<outerLoopIterations; ++i) {
			int randSelection = rand_r(&r)%num_versions;
			int serialSelection = i%num_versions;
			if(i<convergeThreshold) {
				convergingSelection = randSelection;
				dynamicSelection = randSelection;
			}
			if(i%dynamicSwitchThreshold == 0) {
				dynamicSelection = randSelection;
			}
			switch(method) {
			case 0:
				sum += funVersions[0](i,a,b);
				break;
			case 1:
				sum += funVersions[randSelection](i,a,b);
				break;
			case 2:
				sum += funVersions[serialSelection](i,a,b);
				break;
			case 3:
				sum += funVersions[convergingSelection](i,a,b);
				break;
			case 4:
				sum += funVersions[dynamicSelection](i,a,b);
				break;
			case 5:
				sum += funVersions[0](i,a,b);
				break;
			}
		}
		irt_inst_region_end(0);
		noOpt += sum;
	}));
}
EOS

num_versions = ARGV.size > 0 ? ARGV[0].to_i : 1
load_per_fun = ARGV.size > 1 ? ARGV[1].to_i : 10
file_name = ARGV.size > 2 ? ARGV[2] : "out"

fun_repo = ""

version_repo = """
int num_versions = #{num_versions};
funType funVersions[#{num_versions}] = { """

1.upto(num_versions) do |i|
	fun_str = """
	double genFun#{i}(int i, double a, double b) {
		for(int j=0; j<numLoopIterations; ++j) {
#{"\t\t\ta *= b + #{i};\n" * load_per_fun}\t\t}
		return a;
	}
	"""
	fun_repo += fun_str
	version_repo += "genFun#{i}, "
end

version_repo += "};\n\n"

SOURCE_FN = "#{file_name}.cpp"
BIN_FN = "#{file_name}"

# generate cpp file

File.open(SOURCE_FN, "w+") do |source_file|
	source_file.puts pre_str
	source_file.puts fun_repo
	source_file.puts version_repo
	source_file.puts main_str
end

# compile it

compiler = '/software-local/insieme-libs/gcc-latest/bin/g++'
if ENV[MULTIVER_CC]
  compiler = ENV[MULTIVER_CC]
end

papi_dir = '/software-local/insieme-libs/papi-latest'
if ENV[MULTIVER_PAPI_DIR]
  papi_dir = ENV[MULTIVER_PAPI_DIR]
end

irt_defines = '-DIRT_ENABLE_REGION_INSTRUMENTATION -DIRT_USE_PAPI -DIRT_SCHED_POLICY=IRT_SCHED_POLICY_STATIC'
include_paths = "-I/home/petert/insieme_base/code/runtime/include -I/home/petert/insieme_base/code/common/include -I#{papi_dir}/include"

`#{compiler} #{SOURCE_FN} -O3 -std=c++11 #{irt_defines} #{include_paths} -L#{papi_dir}/lib/ -lpapi -lpthread -lrt -o #{BIN_FN}`
