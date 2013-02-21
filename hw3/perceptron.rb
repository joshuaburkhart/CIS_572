#!/usr/bin/ruby

#Usage: ./logistic.rb <train> <test> <eta> <model>

#Example: ./logistic.rb spambase/spambase-train.csv spambase/spambase-test.csv 0.0001 0.1 model.log

require 'matrix'

FileData = Struct.new(:features,:results)
WeightedFeature = Struct.new(:name,:weight)
EPSILON = 0.01
BIAS = 0.0

class Array
    attr_accessor :w0
    def same
        for i in 0..(self.length - 2)
            if(self[i] != self[i + 1])
                return false
            end
        end
        return true
    end
    def to_s
        out_string = "UNKNOWN CLASS"
        if(self[0].class == WeightedFeature)
            out_string = "#{(@w0 * 1000000).round/Float(1000000)}\n"
            self.each {|e|
                pretty_weight = (e.weight * 1000000).round/Float(1000000)
                out_string = "#{out_string}#{e.name} #{pretty_weight}\n"
            }
        end
        return out_string
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

#x is in the format x[column][row] or x[feature][instance]
#y is in the format y[row] or y[instance]
def perceive(x,y,eta)
    eta = Float(eta)
    weights = Array.new(x.length)
    for f in 0..(x.length - 1)
        weights[f] = WeightedFeature.new(x[f].name,0.0)
    end
    count = 0
    errors = 0.0
    w0 = BIAS
    input = w0
    delta = Array.new(x.length,0.0)
    begin
        errors = 0.0
        for k in 0..(x[0].length - 1) #loop over training cases
            input = w0
            for i in 0..(x.length - 1) #loop over features to calculate o
                signal = (x[i][k] > 0) ? 1 : 0
                input += weights[i].weight*signal
            end
            o = (input > 0) ? 1 : 0
            t = (y[k] > 0) ? 1 : 0
            if(t != o)
                errors += 1
            end
            for i in 0..(x.length - 1) #loop over features to update
                signal = (x[i][k] > 0) ? 1 : 0
                weights[i].weight += eta*(t - o)*signal
            end
            w0 += eta*(t - o)
        end
        count += 1
        puts "Errors: #{errors} (#{errors / x[0].length})"
    end while(errors > 0 && count < 100)
    weights.w0 = w0
    return weights
end

def test_model(x,y,model)
    test_probs = Array.new
    accurate_calls = 0.0
    for i in 0..(x[0].length - 1)
        prediction = model.w0
        for j in 0..(x.length - 1)
            prediction += x[j][i]*model[j].weight
        end
        prediction = 1 / (1 + Math.exp(-prediction))
        test_probs << prediction
        if(prediction > 0.5 && y[i] == 1)
            accurate_calls += 1
        elsif(prediction < 0.5 && y[i] == 0)
            accurate_calls += 1
        end
    end
    test_probs << "Accuracy: #{(accurate_calls / x[0].length)}"
    return test_probs
end

train_filename = ARGV[0]
train_data = parse_file(train_filename)
eta = ARGV[2]
model = perceive(train_data.features,train_data.results,eta)

model_view = model.to_s
model_filename = ARGV[3]
model_filehandl = File.open(model_filename,"w")
model_filehandl.puts(model_view)
model_filehandl.close

test_filename = ARGV[1]
test_data = parse_file(test_filename)
test_probs = test_model(test_data.features,test_data.results,model)
puts test_probs
