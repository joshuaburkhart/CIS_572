#!/usr/bin/ruby

#Usage: data_summarizer.rb

#NOTE: This program must be executed in a directory contianing files produced by yahoo_fin_data_parser.rb

require 'set'

years = Set.new
symbols = Set.new
quarters = Set.new

Dir.foreach('.') {|file|
    if(file.match(/([0-9]{4})_(Q[1-4])_cont_([A-Z]+).csv/))
        years.add($1)
        quarters.add($2)
        symbols.add($3)
    end
}

years.each {|year|
    %x(cat #{year}_Q[1-4]_cont_[A-Z]*.csv > #{year}_cont_summary.csv)
}
quarters.each {|quarter|
    %x(cat [0-9]*_#{quarter}_cont_[A-Z]*.csv > #{quarter}_cont_summary.csv)
}
symbols.each {|symbol|
    %x(cat [0-9]*_Q[1-4]_cont_#{symbol}.csv > #{symbol}_cont_summary.csv)
}

