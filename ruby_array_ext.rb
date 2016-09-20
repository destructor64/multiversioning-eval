class Array
	def median
		if length > 0
			sorted_values = self.sort
			length = sorted_values.length
			if length.odd?
				sorted_values[length/2]
			else
				(sorted_values[length/2] + sorted_values[-1+length/2]).to_f / 2
			end
		else
			nil
		end
	end
	
	def geomean
		gm = inject(1.0) { |mul,val| mul*val }
		gm ** (1.0/length)
	end
	
	def mean
		m = inject(0.0) { |a,val| a+val }
		m / length
	end
	
	def sample_variance
		m = self.mean
		sum = self.inject(0){|accum, i| accum +(i-m)**2 }
		sum/(self.length - 1).to_f
	end

	def standard_deviation
		return Math.sqrt(self.sample_variance)
	end
	
	def percentile(percentile)
		sorted_values = sort
		k = (percentile*(sorted_values.length-1)+1).floor - 1
		f = (percentile*(sorted_values.length-1)+1).modulo(1)
		return sorted_values[k] + (f * (sorted_values[k+1] - sorted_values[k]))
	end
end