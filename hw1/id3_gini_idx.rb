#!/usr/bin/ruby

#Usage: ./id3_gini_idx.rb <train> <test> <model>

#Example: ./id3_gini_idx.rb data_sets1/training_set.csv model.log

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

class DecisionNode
    attr_accessor :left
    attr_accessor :right
    attr_accessor :name
    attr_accessor :depth

    def initialize(name,depth)
        @left = Array.new
        @right = Array.new
        @name = name
        @depth = depth
    end
    def to_s
        prefix = "\n#{'| '*@depth}#{name} = "
        left_s = "#{prefix}#{LEFT_VALUE} : #{left.to_s}"
        right_s = "#{prefix}#{RIGHT_VALUE} : #{right.to_s}"
        return "#{right_s}#{left_s}"
    end
end

class TerminalNode
    attr_accessor :results
    attr_accessor :call
    attr_accessor :origin

    def initialize(results)
        @results = results
        @call = nil
    end
    def get_call
        if(@results.nil? || @results.length == 0)
            return nil
        elsif(@results.same)
            return @results[0] == LEFT_VALUE ? LEFT_VALUE : RIGHT_VALUE
        else
            results_tot = Float(@results.length)
            p1 = @results.count(LEFT_VALUE) / results_tot
            p0 = @results.count(RIGHT_VALUE) / results_tot
            return p1 > p0 ? LEFT_VALUE : RIGHT_VALUE
        end
    end
    def to_s
        if(get_call.nil?)
            return "<empty>"
        elsif(@results.same)
            return "#{get_call} pruned due to #{@origin}"
        else
            results_tot = Float(@results.length)
            p1 = @results.count(LEFT_VALUE) / results_tot
            p0 = @results.count(RIGHT_VALUE) / results_tot
            return p1 > p0 ? "#{LEFT_VALUE} (#{(p1*1000000).round/Float(10000)}%) pruned due to #{@origin}" : "#{RIGHT_VALUE} (#{(p0*1000000).round/Float(10000)}%) pruned due to #{@origin}"
        end 
    end
end

FileData = Struct.new(:features,:results)

def select_best_feature(features,results)
    gini_coefs = Array.new
    features.each { |f|
        left_results = Array.new
        right_results = Array.new
        for i in 0..(results.length - 1)
            if(f[i] == LEFT_VALUE)
                left_results << results[i]
            elsif(f[i] == RIGHT_VALUE)
                right_results << results[i]
            else
                puts "ERROR, UNEXPECTED VALUE: #{f[i]}"
                exit
            end
        end

        gini_coefs << (calc_gini(left_results) + calc_gini(right_results))
    }
    #uncommenting the below lines will print the root-node information gains
    #puts gini_coefs
    #puts "gini_coefs.max #{gini_coefs.max}"
    #puts "gini_coefs.index(gini_coefs.max): #{gini_coefs.index(gini_coefs.max)}"
    #exit
    return features[gini_coefs.index(gini_coefs.min)]
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

def calc_gini(unsorted_ary)
    sorted_ary = unsorted_ary.sort
    n = Float(sorted_ary.length)
    top_sum = Float(0)
    for i in 1..n
        yi = sorted_ary[i - 1]
        top_sum += (n + 1 - i)*yi
    end
    bottom_sum = Float(0)
    for i in 1..n
        yi = sorted_ary[i - 1]
        bottom_sum += yi
    end
    g = nil
    if(bottom_sum > 0)
        g = (1/n)*(n + 1 - 2*(top_sum/bottom_sum))
    else
        g = (1/n)*(n + 1)
    end
    return g
end

def build_model(features,results,parent_gini_coef,depth=0)
    gini_coef = calc_gini(results)
    puts "new child.. with coef #{gini_coef}"
    puts "results.same? #{results.same}"
    puts "parent_gini_coef: #{parent_gini_coef}"
    puts "gini_coef >= parent_gini_coef? #{gini_coef >= parent_gini_coef}"
    if(results.same || gini_coef >= parent_gini_coef)
        t = TerminalNode.new(results.clone)
        t.origin = results.same ? "consensus value" : "gini_score reached #{gini_coef}"
        return t
    else
        f = select_best_feature(features.clone,results.clone)
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
            if(f[i] == LEFT_VALUE)
                left_results << results[i]
                left_features.each {|left_feature|
                    left_feature << features.select {|e| e.name == left_feature.name}[0][i]
                }
            elsif(f[i] == RIGHT_VALUE)
                right_results << results[i]
                right_features.each {|right_feature|
                    right_feature << features.select {|e| e.name == right_feature.name}[0][i]
                }
            else
                puts "ERROR, UNEXPECTED VALUE: #{f[i]}"
                exit
            end
        end
        node = DecisionNode.new(f.name,depth)
        node.left = build_model(left_features.clone,left_results,gini_coef,depth + 1)
        node.right = build_model(right_features.clone,right_results,gini_coef,depth + 1)
        return node
    end
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
bootstrap_gini_coef = calc_gini(train_data.results)
model = build_model(train_data.features,train_data.results,bootstrap_gini_coef)

test_filename = ARGV[1]
test_data = parse_file(test_filename)
test_miscalls = test_model(test_data.features,test_data.results,model)
tests = Float(test_data.results.length)
#stupid rounding trick for ruby 1.8.7
puts "Accuracy: #{tests - test_miscalls}/#{tests} = #{(((tests - test_miscalls)/tests)*1000000).round/Float(10000)}"

model_view = model.to_s
model_filename = ARGV[2]
model_filehandl = File.open(model_filename,"w")
model_filehandl.puts(model_view)
model_filehandl.close
