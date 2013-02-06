#!/usr/bin/ruby

#Usage: ./nb.rb <train> <test> <beta> <model>

#Example:

LEFT_VALUE = 1
RIGHT_VALUE = 0

class Array
    def same
        for i in 0..(self.length - 2)
            if(self[i] != self[i + 1])
                return false
            end
        end
        return true
    end
end

class Column < Array
    attr_accessor :name

    def to_s
        puts "#{@name}: #{self.inspect}"
    end
end

FileData = Struct.new(:features,:results)

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
    logodds = Hash.new
    basep1 = (results.count(1) + Float(beta) - 1) / (Float(results.length) + 2*Float(beta) - 2)
    basep0 = (results.count(0) + Float(beta) - 1) / (Float(results.length) + 2*Float(beta) - 2)
    blo_first_term = Math.log(basep1/basep0)
    blo_scnd_term = 0
    features.each {|f|
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
        logodds[f.name] = (Math.log(p1_given_base1 / p1_given_base0) - Math.log(p0_given_base1 / p0_given_base0)) 
        blo_scnd_term += Math.log(p0_given_base1/p0_given_base0)
    }
    blo = blo_first_term + blo_scnd_term
    logodds[''] = blo
    puts logodds.inspect
end

def test_model(features,results,model)
    if(model.class == TerminalNode)
        if(!model.get_call.nil?)
            call = model.get_call
            miscalls = results.length - results.count(call)
        else
            puts "ERROR TESTING MODEL"
            puts "results: #{results.inspect}"
            exit
        end
        return miscalls
    else
        cur_f_name = model.name
        cur_f = nil
        features.each { |f|
            if(f.name == cur_f_name)
                cur_f = f
                break
            end
        }
        left_features = Array.new
        right_features = Array.new
        features.each {|orig_feature|
            left_feature = Column.new
            right_feature = Column.new
            left_feature.name = orig_feature.name
            right_feature.name = orig_feature.name
            left_features << left_feature
            right_features << right_feature
        }
        left_results = Array.new
        right_results = Array.new
        for i in 0..(results.length - 1)
            if(cur_f[i] == LEFT_VALUE)
                left_results << results[i]
                left_features.each {|left_feature|
                    left_feature << features.select {|e| e.name == left_feature.name}[0][i]
                }
            elsif(cur_f[i] == RIGHT_VALUE)
                right_results << results[i]
                right_features.each {|right_feature|
                    right_feature << features.select {|e| e.name == right_feature.name}[0][i]
                }
            else
                puts "ERROR, UNEXPECTED VALUE: #{cur_f[i]}"
                exit
            end
        end
        left_miscalls = test_model(left_features.clone,left_results,model.left)
        right_miscalls = test_model(right_features.clone,right_results,model.right)
        return left_miscalls + right_miscalls
    end
end

train_filename = ARGV[0]
train_data = parse_file(train_filename)
beta = ARGV[2]
logodds = calc_logodds(train_data.features,train_data.results,beta)

test_filename = ARGV[1]
test_data = parse_file(test_filename)
test_miscalls = test_model(test_data.features,test_data.results,logodds)
tests = Float(test_data.results.length)
#stupid rounding trick for ruby 1.8.7
puts "Accuracy: #{(((tests - test_miscalls)/tests)*10000).round/Float(100)}%"

logodds_view = logodds.to_s
logodds_filename = ARGV[3]
logodds_filehandl = File.open(model_filename,"w")
logodds_filehandl.puts(model_view)
logodds_filehandl.close
