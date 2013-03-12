#!/usr/bin/ruby

#Usage: validator.rb <learner> <parsed csv>

#Example: validator.rb logistic.rb parsed_output/Q1_summary.csv

require 'thread'

K = 10
mutex = Mutex.new

learner = ARGV[0]
csv_filename = ARGV[1]
num_rows = %x(cat #{csv_filename} | wc -l).strip.to_i
folds = num_rows / K
thread_collection = Array.new
folds.times {|j|
    i = j+1
    puts "starting fold #{i} of #{folds}..."
    thread_collection[i] = Thread.new {
        id = Thread.current.object_id
        t = "training_mt_filename.#{id}"
        v = "validation_mt_filename.#{id}"
        validation_filehandl = File.open(v,"w")
        training_filehandl = File.open(t,"w")
        csv_filehandl = File.open(csv_filename,"r")
        line_num = 1
        while(data_line = csv_filehandl.gets)
            if((line_num % folds) == (i % folds))
                validation_filehandl.puts(data_line)
            else
                training_filehandl.puts(data_line)
            end
            line_num += 1
        end
        csv_filehandl.close
        validation_filehandl.close
        training_filehandl.close
        command = "./#{learner} #{t} #{v}"
        result = Float(%x(#{command}).strip)
        Thread.current["acc"] = result
        %x(rm -f #{t} #{v})
    }
}
acc_sum = 0.0
folds.times {|j|
    i = j+1
    thread = thread_collection[i]
    thread.join
    acc_sum += thread["acc"]
}
puts acc_sum / Float(folds)
