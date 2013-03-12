#!/usr/bin/ruby

#Usage: gen_synthetic_data.rb <file to dilute with random data>

#Example:

#NOTE: This program produces one pure and one 50% diluted.

real_data_filename = ARGV[0]

real_data_filehandl = File.open(real_data_filename,"r")
diluted_filehandl = File.open("#{real_data_filename}.diluted","w")
pure_filehandl = File.open("#{real_data_filename}.pure","w")

count = 0
while(real_data_line = real_data_filehandl.gets)
    64.times {
        if(count % 2 == 0)
            diluted_filehandl.print("#{rand(2)},")
        end
        pure_filehandl.print("1,")
    }
    if(count % 2 == 1)
        diluted_filehandl.print(real_data_line)
    else
        diluted_filehandl.print("#{rand(2)}")
        diluted_filehandl.puts
    end
    pure_filehandl.print("1")
    pure_filehandl.puts
    count += 1
end
real_data_filehandl.close
diluted_filehandl.close
pure_filehandl.close
