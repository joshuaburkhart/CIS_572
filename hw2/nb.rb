#!/usr/bin/ruby

#Usage: ./nb.rb <train> <test> <beta> <model>

#Example:

LEFT_VALUE = 1
RIGHT_VALUE = 0

FileData = Struct.new(:features,:results)
AttrBeta = Struct.new(:name,:prob)

class Array
    def same
        for i in 0..(self.length - 2)
            if(self[i] != self[i + 1])
                return false
            end
        end
        return true
    end
    def to_s
        if(self[0].class == AttrBeta)
            self.each {|e|
                puts "#{e.name}#{e.prob}"
            }
        end
    end
end

class Column < Array
    attr_accessor :name

    def to_s
        puts "#{@name}: #{self.inspect}"
    end
end

def parse_file(filename)
    filehandl = File.open(filename,"r")
    header = filehandl.gets
    col_name_ary = header.split(/,/)

    features = Array.new
    for i in 0..(col_name_ary.length - 2)
        f = Column.new
        f.name = col_name_ary[i]
        features << f
    end

    results = Column.new
    results.name = col_name_ary[col_name_ary.length - 1]

    while(dataline = filehandl.gets)
        data_ary = dataline.split(/,/)
        for i in 0..(data_ary.length - 2)
            features[i] << Float(data_ary[i])
        end
        results << Float(data_ary[data_ary.length - 1])
    end

    filehandl.close
    return FileData.new(features,results)
end

def calc_logodds(features,results,beta)
    logodds = Array.new
    basep1 = (results.count(1) + Float(beta) - 1) / (Float(results.length) + 2*Float(beta) - 2)
    basep0 = (results.count(0) + Float(beta) - 1) / (Float(results.length) + 2*Float(beta) - 2)
    blo_first_term = Math.log(basep1/basep0)
    blo_scnd_term = 0
    features.each_with_index {|f,idx|
        result1_features = Array.new
        result0_features = Array.new
        for i in 0..(results.length - 1)
            if(results[i] == 1)
                result1_features << f[i]
            elsif(results[i] == 0)
                result0_features << f[i]
            else
                puts "ERROR, UNEXPECTED VALUE: #{f[i]}"
                exit
            end 
        end
        p1_given_base1 = (result1_features.count(1) + Float(beta) - 1) / (Float(results.count(1)) + 2*Float(beta) - 2)
        p1_given_base0 = (result0_features.count(1) + Float(beta) - 1) / (Float(results.count(0)) + 2*Float(beta) - 2)
        p0_given_base1 = (result1_features.count(0) + Float(beta) - 1) / (Float(results.count(1)) + 2*Float(beta) - 2)
        p0_given_base0 = (result0_features.count(0) + Float(beta) - 1) / (Float(results.count(0)) + 2*Float(beta) - 2)
        logodds[idx+1] = AttrBeta.new("#{f.name} ",(Math.log(p1_given_base1 / p1_given_base0) - Math.log(p0_given_base1 / p0_given_base0)))
        blo_scnd_term += Math.log(p0_given_base1/p0_given_base0)
    }
    blo = blo_first_term + blo_scnd_term
    logodds[0] = AttrBeta.new('',blo)
    return logodds
end

def test_model(features,results,model)
    test_probs = Array.new
    blo = model.select {|e| e.name == ''}
    for i in 0..(results.length - 1)
        flo = 0
        features.each {|f|
            if(f[i] == 1)
                fbeta = model.select {|l| l.name == "#{f.name} "}
                flo += Float(fbeta[0].prob)
            end
        }    
        test_probs << Float(blo[0].prob) + flo
    end
    puts test_probs.inspect
    exit
end

train_filename = ARGV[0]
train_data = parse_file(train_filename)
beta = ARGV[2]
model = calc_logodds(train_data.features,train_data.results,beta)

test_filename = ARGV[1]
test_data = parse_file(test_filename)
test_probs = test_model(test_data.features,test_data.results,model)
test_probs.to_s

model_view = model.to_s
model_filename = ARGV[3]
model_filehandl = File.open(model_filename,"w")
model_filehandl.puts(model_view)
model_filehandl.close
