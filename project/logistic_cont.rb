#!/usr/bin/ruby

#Usage: ./logistic.rb <train> <test>

#Example: ./logistic.rb spambase/spambase-train.csv spambase/spambase-test.csv

require 'matrix'

FileData = Struct.new(:features,:results)
WeightedFeature = Struct.new(:name,:weight)
EPSILON = 0.01
ETA = 0.0001
SIGMA = 0.1
MODEL = "logistic_model.log"

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
    header = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,prediction"
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
def regress(x,y)
    weights = Array.new(x.length)
    for f in 0..(x.length - 1)
        weights[f] = WeightedFeature.new(x[f].name,0.0)
    end
    w0 = 0.0
    weight_magnitude = 0
    old_gradient = 0
    gradient = 0
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
            wisum = wisum - (old_weights[i].weight / SIGMA**2)
            weights[i].weight = old_weights[i].weight + ETA*wisum
            weight_magnitude += weights[i].weight**2
            gradient += wisum**2
        end
        w0sum = w0sum - (w0 / SIGMA**2)
        w0 = w0 + ETA*w0sum
        gradient += w0sum**2
        gradient = gradient**(1.0/2)
        weight_magnitude = weight_magnitude**(1.0/2)
    end while((old_gradient - gradient).abs > EPSILON)
    weights.w0 = w0
    return weights
end

def test_model(x,y,model)
    test_probs = Array.new
    n = x[0].length
    x_sum = 0.0
    y_sum = 0.0
    for i in 0..(n - 1)
        prediction = model.w0
        for j in 0..(x.length - 1)
            prediction += x[j][i]*model[j].weight
        end
        prediction = 1 / (1 + Math.exp(-prediction))
        test_probs << prediction
        x_sum += prediction
        y_sum += y[i]
    end
    x_mean = x_sum / n
    y_mean = y_sum / n
    x_var_sum = 0.0
    y_var_sum = 0.0
    xy_covar_sum = 0.0
    for i in 0..(n - 1)
        x_error = (test_probs[i] - x_mean)
        y_error = (y[i] - y_mean)
        x_var_sum += x_error**2
        y_var_sum += y_error**2
        xy_covar_sum += x_error*y_error
    end
    x_var = x_var_sum / n
    y_var = y_var_sum / n
    xy_covar = xy_covar_sum / n
    lins_concordance = (2*xy_covar) / (x_var + y_var + (x_mean - y_mean)**2)
    puts lins_concordance
    return test_probs
end

train_filename = ARGV[0]
train_data = parse_file(train_filename)
model = regress(train_data.features,train_data.results)

model_view = model.to_s
model_filehandl = File.open(MODEL,"w")
model_filehandl.puts(model_view)
model_filehandl.close

test_filename = ARGV[1]
test_data = parse_file(test_filename)
test_probs = test_model(test_data.features,test_data.results,model)
#puts test_probs
