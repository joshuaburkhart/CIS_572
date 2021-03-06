#!/usr/bin/ruby

#Usage: validator.rb <learner> <parsed csv>

#Example: validator.rb logistic.rb parsed_output/Q1_summary.csv

T = "training_filename"
V = "validation_filename"
K = 10

learner = ARGV[0]
csv_filename = ARGV[1]
num_rows = %x(cat #{csv_filename} | wc -l).strip.to_i
folds = num_rows / K
acc_sum = 0.0
for i in 1..folds
    puts "starting fold #{i} of #{folds}..."
    validation_filehandl = File.open(V,"w")
    training_filehandl = File.open(T,"w")
    csv_filehandl = File.open(csv_filename,"r")
    line_num = 1
    while(data_line = csv_filehandl.gets)
        if((line_num % folds) == (i % folds))
            puts "validation including line #{line_num}"
            validation_filehandl.puts(data_line)
        else
            training_filehandl.puts(data_line)
        end
        line_num += 1
    end
    validation_filehandl.close
    training_filehandl.close
    command = "./#{learner} #{T} #{V}"
    output = %x(#{command})
    numeric_out = Float(output.strip)
    acc_sum += numeric_out 
    puts "current accuracy: #{acc_sum / i}"
    %x(rm -f #{T} #{V})
    csv_filehandl.close
end
puts acc_sum / Float(folds)
