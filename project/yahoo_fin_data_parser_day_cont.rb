#!/usr/bin/ruby

#Usage: yahoo_fin_data_parser.rb <csv from finance.yahoo.com>

#Example: yahoo_fin_data_parser.rb CBST.csv

#NOTE: This program produces files containing quarterly movements.

INVALID = "<invalid>"

q1_start = INVALID
q2_start = INVALID
q3_start = INVALID
q4_start = INVALID
q1_finsh = INVALID
q2_finsh = INVALID
q3_finsh = INVALID
q4_finsh = INVALID

next_month = nil
crnt_month = nil
next_q_val = nil
next_q_mov = nil
next_d_price = nil
crnt_d_price = nil
crnt_data_line = nil

lagging_data_line = nil

csv_file = ARGV[0]
data_filehandl = File.open(csv_file,"r")
csv_file.match(/([A-Z]+.csv)/)
csv_filename = $1

while(data_line = data_filehandl.gets)
    if(data_line.match(/^[0-9]{4}-([0-9]{2})-[0-9]{2},.+,.+,.+,.+,.+,.+$/))
        if(next_month.nil?)
            next_month = $1
        end
        crnt_month = $1
        if(crnt_month != next_month)
            case crnt_month
            when "12"
                lagging_data_line.match(/^[0-9]{4}-([0-9]{2}-[0-9]{2}),.+,.+,.+,.+,.+,.+$/)
                q2_start = $1
                data_line.match(/^[0-9]{4}-([0-9]{2}-[0-9]{2}),.+,.+,.+,.+,.+,.+$/)
                q1_finsh = $1
            when "09"
                lagging_data_line.match(/^[0-9]{4}-([0-9]{2}-[0-9]{2}),.+,.+,.+,.+,.+,.+$/)
                q1_start = $1
                data_line.match(/^[0-9]{4}-([0-9]{2}-[0-9]{2}),.+,.+,.+,.+,.+,.+$/)
                q4_finsh = $1

            when "06"
                lagging_data_line.match(/^[0-9]{4}-([0-9]{2}-[0-9]{2}),.+,.+,.+,.+,.+,.+$/)
                q4_start = $1
                data_line.match(/^[0-9]{4}-([0-9]{2}-[0-9]{2}),.+,.+,.+,.+,.+,.+$/)
                q3_finsh = $1

            when "03"
                lagging_data_line.match(/^[0-9]{4}-([0-9]{2}-[0-9]{2}),.+,.+,.+,.+,.+,.+$/)
                q3_start = $1
                data_line.match(/^[0-9]{4}-([0-9]{2}-[0-9]{2}),.+,.+,.+,.+,.+,.+$/)
                q2_finsh = $1
            end
        end
        next_month = crnt_month
        if(!lagging_data_line.nil?)
            if(next_q_val.nil? && lagging_data_line.match(/^[0-9]{4}-(#{q1_start}|#{q2_start}|#{q3_start}|#{q4_start}).+$/))
                lagging_data_line.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2},.+,.+,.+,.+,.+,(.+)$/)
                next_q_val = Float($1)
            elsif(next_q_mov.nil? && lagging_data_line.match(/^[0-9]{4}-(#{q1_finsh}|#{q2_finsh}|#{q3_finsh}|#{q4_finsh}).+$/))
                lagging_data_line.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2},.+,.+,.+,.+,.+,(.+)$/)
                crnt_q_val = Float($1)
                next_q_mov = ((next_q_val - crnt_q_val) / next_q_val) * 100.0
                crnt_data_line = ["#{next_q_mov}"]
                next_d_price = crnt_q_val
                next_q_val = crnt_q_val
            elsif(!crnt_data_line.nil? && lagging_data_line.match(/^([0-9]{4})-(#{q1_start}|#{q2_start}|#{q3_start}|#{q4_start}).+$/))
                crnt_data_line << ["0"]
                #we assume more recent days have more influence and want a uniform number of features
                while(crnt_data_line.length < 65)
                    crnt_data_line << ["0"]
                end
                crnt_data_line.reverse!
                crnt_filename = $1
                case $2
                when q1_start
                    crnt_filename << "_Q4_"
                when q2_start
                    crnt_filename << "_Q1_"
                when q3_start
                    crnt_filename << "_Q2_"
                when q4_start
                    crnt_filename << "_Q3_"
                else
                    puts "ERROR: UNRECOGNIZED QUARTER"
                    puts "#{lagging_data_line}"
                    puts "q1_start: #{q1_start}"
                    puts "q2_start: #{q2_start}"
                    puts "q3_start: #{q3_start}"
                    puts "q4_start: #{q4_start}"
                    puts "q1_finsh: #{q1_finsh}"
                    puts "q2_finsh: #{q2_finsh}"
                    puts "q3_finsh: #{q3_finsh}"
                    puts "q4_finsh: #{q4_finsh}"
                    puts "crnt_data_line: #{crnt_data_line.join(',')}"
                    puts "crnt_month: #{crnt_month}"
                    puts "next_month: #{next_month}"
                    exit
                end
                crnt_filename << "cont_"
                crnt_filename << csv_filename
                crnt_filehandl = File.open(crnt_filename,"w")
                crnt_filehandl.puts(crnt_data_line.join(','))
                crnt_filehandl.close
                next_q_mov = nil
            elsif(!next_d_price.nil? && lagging_data_line.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2},.+,.+,.+,.+,.+,(.+)$/))
                crnt_d_price = Float($1)
                crnt_d_mov = ((next_d_price - crnt_d_price) / next_d_price) * 100.0
                crnt_data_line << ["#{crnt_d_mov}"]
                next_d_price = crnt_d_price
            end
        end
        lagging_data_line = data_line
    end
end

data_filehandl.close
