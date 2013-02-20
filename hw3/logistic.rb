#!/usr/bin/ruby

#Usage: ./logistic.rb <train> <test> <eta> <sigma> <model>

#Example:

FileData = Struct.new(:features,:results)
AttrBeta = Struct.new(:name,:prob)
EPSILON = 0.000001

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

def regress(x,y,eta,sigma)
    g = nil
    weights = Array.new(x.length,0)
    weights[0] = 1
    begin
        g = 0
        for k in x.length
            sum = 0
            for i in x.length.length
                z = weights[0]
                for j in x.length
                    z += weights[j] * x[j][i]
                end
                h = 1 / (1 + Math::E**(-z))
                sum += (h - y[i]) * x[k][i] + (x[i][k] / sigma**2)
            end
            weights[k] = weights[k] - eta * (1/x.length.length) * sum
            g += weights[k]
        end
    end while(g > EPSILON)
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
model = regress(train_data.features,train_data.results,eta,sigma)

puts model
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
