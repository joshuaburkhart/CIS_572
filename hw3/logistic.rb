#!/usr/bin/ruby

#Usage: ./logistic.rb <train> <test> <eta> <sigma> <model>

#Example:

require 'matrix'

FileData = Struct.new(:features,:results)
AttrBeta = Struct.new(:name,:prob)
EPSILON = 0.01

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
        out_string = ""
        if(self[0].class == AttrBeta)
            self.each {|e|
                pretty_prob = (e.prob * 1000000).round/Float(1000000)
                out_string = "#{out_string}#{e.name}#{pretty_prob}\n"
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
    weights = Array.new(x.length,0.0) #initialize weights to 0
    w0 = 0.0
    weight_magnitude = 0
    old_gradient = 0
    gradient = 0
    count = 0
    begin
        puts "weight_magnitude = #{weight_magnitude}"
        weight_magnitude = 0
        old_gradient = gradient
        gradient = 0
        old_weights = weights.clone
        h_ary = Array.new
        w0sum = 0
        for j in 0..(x[0].length - 1)
            z = w0
            for k in 0..(x.length - 1) #calculate weightsT * X
                z += old_weights[k]*x[k][j]
            end
            h_ary[j] = 1 / (1 + Math.exp(-z))
            w0sum += (y[j] - h_ary[j])
        end
        for i in 0..(x.length - 1) #update features
            wisum = 0
            for j in 0..(x[0].length - 1)
                wisum += x[i][j]*(y[j] - h_ary[j])
            end
            wisum = (wisum - old_weights[i] / sigma**2)
            weights[i] = old_weights[i] + eta*wisum
            weight_magnitude += weights[i]**2
            gradient += wisum**2
        end
        w0sum = (w0sum - w0 / sigma**2)
        w0 = w0 + eta*w0sum
        gradient += w0sum**2
        gradient = gradient**(1.0/2)
        puts "gradient magnitude = #{gradient}"
        puts "gradient difference = #{(old_gradient - gradient).abs}"
        weight_magnitude = weight_magnitude**(1.0/2)
        count += 1
    end while((old_gradient - gradient).abs > EPSILON && count < 100)
    return weights
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
        w = Float(blo[0].prob) + flo
        test_probs << 1/(1 + Math::E**-w)
    end
    return test_probs
end

train_filename = ARGV[0]
train_data = parse_file(train_filename)
eta = ARGV[2]
sigma = ARGV[3]
puts "using eta = #{eta} and sigma = #{sigma}"
model = regress(train_data.features,train_data.results,eta,sigma)

puts model
puts model.to_s
exit

test_filename = ARGV[1]
test_data = parse_file(test_filename)
test_probs = test_model(test_data.features,test_data.results,model)
puts test_probs

model_view = model.to_s
model_filename = ARGV[4]
model_filehandl = File.open(model_filename,"w")
model_filehandl.puts(model_view)
model_filehandl.close
