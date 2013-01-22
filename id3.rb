#!/usr/bin/ruby

#Usage: ./id3 <train> <test> <model>

#Example:

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
        right_s = "#{prefix}0 : #{right.to_s}"
        left_s = "#{prefix}1 : #{left.to_s}"
        return "#{right_s}#{left_s}"
    end
end

class TerminalNode
    def initialize(results)
        @results = results
    end
    def to_s
        if(@results.nil? || @results.length == 0)
            return "<empty>"
        elsif(@results.same)
            return "#{@results[0]}"
        else
            results_tot = Float(@results.length)
            p0 = @results.count(0) / results_tot
            p1 = @results.count(1) / results_tot
            return p0 > p1 ? "#{p0} prob. 0" : "#{p1} prob. 1"
        end
    end
end

def select_best_feature(features,results)
    results_tot = Float(results.length)
    p0 = results.count(0) / results_tot
    p1 = results.count(1) / results_tot
    results_0_entropy = p0 > 0 ? -p0*Math.log(p0) : 0
    results_1_entropy = p1 > 0 ? -p1*Math.log(p1) : 0
    prior_entropy = results_0_entropy + results_1_entropy
    info_gains = Array.new
    features.each { |f|
        left_results = Array.new
        right_results = Array.new
        for i in 0..(results.length - 1)
            if(f[i] == 1)
                left_results << results[i]
            else
                right_results << results[i]
            end
        end
        left_w_entropy = 0
        left_tot = Float(left_results.length)
        if(left_tot > 0)
            pleft_0 = left_results.count(0) / left_tot
            pleft_1 = left_results.count(1) / left_tot
            left_0_entropy = pleft_0 > 0 ? -pleft_0*Math.log(pleft_0) : 0
            left_1_entropy = pleft_1 > 0 ? -pleft_1*Math.log(pleft_1) : 0
            left_entropy = left_0_entropy + left_1_entropy
            left_weight = left_tot / results_tot
            left_w_entropy = left_weight * left_entropy
        end

        right_w_entropy = 0
        right_tot = Float(right_results.length)
        if(right_tot > 0)
            pright_0 = right_results.count(0) / right_tot
            pright_1 = right_results.count(1) / right_tot
            right_0_entropy = pright_0 > 0 ? -pright_0*Math.log(pright_0) : 0
            right_1_entropy = pright_1 > 0 ? -pright_1*Math.log(pright_1) : 0
            right_entropy = right_0_entropy + right_1_entropy
            right_weight = right_tot / results_tot
            right_w_entropy = right_weight * right_entropy
        end

        posterior_entropy = left_w_entropy + right_w_entropy
        info_gains << (prior_entropy - posterior_entropy) #should be > 0
    }
    #puts info_gains
    return features[info_gains.index(info_gains.max)]
end

def build_tree(features,results,depth=0)
    if(results.same || features.length == 0)
        return TerminalNode.new(results)
    else
        f = select_best_feature(features,results)
        left_results = Array.new
        right_results = Array.new
        for i in 0..(results.length - 1)
            if(f[i] == 1)
                left_results << results[i]
            else
                right_results << results[i]
            end
        end
        features.delete(f)
        node = DecisionNode.new(f.name,depth)
        node.left = build_tree(features.clone,left_results,depth + 1)
        node.right = build_tree(features.clone,right_results,depth + 1)
        return node
    end
end

train_filename = ARGV[0]
train_filehandl = File.open(train_filename,"r")
train_header = train_filehandl.gets
col_name_ary = train_header.split(/,/)

features = Array.new
for i in 0..(col_name_ary.length - 2)
    f = Column.new
    f.name = col_name_ary[i]
    features << f
end

results = Column.new
results.name = col_name_ary[col_name_ary.length - 1]

while(train_dataline = train_filehandl.gets)
    data_ary = train_dataline.split(/,/)
    for i in 0..(data_ary.length - 2)
        features[i] << Float(data_ary[i])
    end
    results << Float(data_ary[data_ary.length - 1])
end

train_filehandl.close

tree = build_tree(features,results)
model_view = tree.to_s

model_filename = ARGV[1]
model_filehandl = File.open(model_filename,"w")
model_filehandl.puts(model_view)
model_filehandl.close
