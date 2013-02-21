#!/usr/bin/ruby

#Usage: ./logistic.rb <train> <test> <eta> <sigma> <model>

#Example: ./logistic.rb spambase/spambase-train.csv spambase/spambase-test.csv 0.0001 0.1 model.log

require 'matrix'

FileData = Struct.new(:features,:results)
WeightedFeature = Struct.new(:name,:weight)
EPSILON = 0.01

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
def regress(x,y,eta,sigma)
    eta = Float(eta)
    sigma = Float(sigma)
    weights = Array.new(x.length)
    for f in 0..(x.length - 1)
        weights[f] = WeightedFeature.new(x[f].name,0.0)
    end
    w0 = 0.0
    weight_magnitude = 0
    old_gradient = 0
    gradient = 0
    count = 0
    begin
        weight_magnitude = 0
        old_gradient = gradient
        gradient = 0
        old_weights = weights.clone
        h_ary = Array.new
        w0sum = 0
        for j in 0..(x[0].length - 1) #loop over training examples
            z = w0
            for k in 0..(x.length - 1) #calculate weightsT * X
                z += old_weights[k].weight*x[k][j]
            end
            h_ary[j] = 1 / (1 + Math.exp(-z)) #calculate and store hypotheses
            w0sum += (y[j] - h_ary[j])
        end
        for i in 0..(x.length - 1) #update features
            wisum = 0
            for j in 0..(x[0].length - 1) #loop over training examples
                wisum += x[i][j]*(y[j] - h_ary[j]) #recall precomputed hypotheses
            end
            wisum = wisum - (old_weights[i].weight / sigma**2)
            weights[i].weight = old_weights[i].weight + eta*wisum
            weight_magnitude += weights[i].weight**2
            gradient += wisum**2
        end
        w0sum = w0sum - (w0 / sigma**2)
        w0 = w0 + eta*w0sum
        gradient += w0sum**2
        gradient = gradient**(1.0/2)
        weight_magnitude = weight_magnitude**(1.0/2)
        count += 1
    end while((old_gradient - gradient).abs > EPSILON && count < 100)
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
sigma = ARGV[3]
model = regress(train_data.features,train_data.results,eta,sigma)

model_view = model.to_s
model_filename = ARGV[4]
model_filehandl = File.open(model_filename,"w")
model_filehandl.puts(model_view)
model_filehandl.close

test_filename = ARGV[1]
test_data = parse_file(test_filename)
test_probs = test_model(test_data.features,test_data.results,model)
puts test_probs
