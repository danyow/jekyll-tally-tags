module Jekyll
  module TallyTags
    class Counter

      # 两处赋值
      # @param [Document] doc
      # @param [String] key
      # @param [Object] value
      def self.set_doc_data(doc, key, value)
        doc.data[key]       = value
        doc.data[DATA][key] = value
      end

      # 两处添加
      # @param [Document] doc
      # @param [String] key
      # @param [Object] value
      def self.add_doc_data(doc, key, value)
        doc.data[key]       = [] if !doc.data[key]
        doc.data[DATA][key] = [] if !doc.data[DATA][key]
        doc.data[key] << value
        doc.data[DATA][key] << value
      end

      # @param [Float] number
      # @param [String] format
      def self.to_f_s(number, format)
        if number - number.round != 0
          format % number.round(2).to_s
        else
          format % number.round.to_s
        end
      end

      # @param [Array, Object]
      # @return [Array]
      def self.to_array(single_or_array, default)
        if !single_or_array
          return default
        end
        if single_or_array.is_a?(Array)
          single_or_array
        else
          [single_or_array]
        end
      end

      # @param [Array<Array<String>>] merge_list
      # @param [Array<Document>] docs
      # @param [String] find
      # @param [String] to
      def self.combine_merge_list(merge_list, docs, find, to)
        merge_list.each do |merges|
          docs.each do |doc|
            (0..doc.data[find].size - 1).each do |index|
              if merges.include?(doc.data[find][index])
                self.add_doc_data(doc, to, merges) unless doc.data[to].include?(merges)
              end
            end
          end
        end
      end

      # @param [Array<String>] items 原始数据
      # @param [Integer, Array<Integer>] deep_key 合并类型
      # @return [Array<Array<String>>]
      def self.merge_all(items, deep_key)
        hash    = {}
        is_deep = false
        if items.size > 2
          deep_key = ALL if !deep_key
          # all 情况
          if deep_key.is_a?(String)
            if deep_key == ALL
              is_deep = true
              (2..items.size).each do |deep|
                hash[deep] = self.merge(items, nil, nil, deep, 0, 0, 0)
              end
            end
          end

          # 单个
          if deep_key.is_a?(Integer)
            if deep_key != 0 && deep_key >= 2
              is_deep        = true
              hash[deep_key] = self.merge(items, nil, nil, deep_key, 0, 0, 0)
            end
          end

          # 数组
          if deep_key.is_a?(Array)
            deep_key.each do |deep|
              if deep != 0 && deep >= 2
                is_deep    = true
                hash[deep] = self.merge(items, nil, nil, deep, 0, 0, 0)
              end
            end
          end

          if !is_deep
            Jekyll.logger.warn(COUNTER, "#{deep_key}类型未知")
          end

          all = []
          hash.values.each do |values|
            all += values
          end
          all
        else
          [items]
        end
      end

      # @param [Array<String>] items 原始数据
      # @param [Array<Array<String>>] deep_items 对应深度数据的保存数组
      # @param [Array<String>] into_items 遍历时 当前深度 的 保存数组 会 添加到 对应深度数据的保存数组
      # @param [Integer] deep 总深度
      # @param [Integer] cur_deep 当前深度
      # @param [Integer] s 起始下标
      # @param [Integer] e 结束下标
      # @return [Array<Array<String>>]
      def self.merge(items, deep_items, into_items, deep, cur_deep, s, e)
        if !deep_items
          deep_items = []
          into_items = []
          cur_deep   = 0
          s          = 0
          e          = items.size - deep
        end
        (s..e).each do |i|
          temp = Array.new(into_items) << items[i]
          if cur_deep == deep - 1
            deep_items << temp
          else
            deep_items += self.merge(items, [], temp, deep, cur_deep + 1, i + 1, e + 1)
          end
        end
        deep_items
      end

      # @param [Integer] a
      # @param [Integer] b
      def self.sum(a, b)
        a.to_f + b.to_f
      end

      # @param [Integer] a
      # @param [Integer] b
      def self.div(a, b)
        a.to_f / b.to_f
      end

      # @param [Integer] a
      # @param [Integer] b
      def self.mul(a, b)
        a.to_f * b.to_f
      end

      # @param [Integer] a
      # @param [Integer] b
      def self.sub(a, b)
        a.to_f - b.to_f
      end

      # @example
      #   ":sub_2和:2:3" => [":sub_2", "和", ":2", ":3"]
      # @param [String]
      # @return [Array<String>]
      def self.partition_all(formatter)
        result = []
        temps  = formatter.partition(/:\w+/)
        (0..temps.size - 1).each do |index|
          temp = temps[index]
          if index == temps.size - 1
            if !temp.empty?
              result += self.partition_all(temp)
            end
          else
            if temp && !temp.empty?
              result << temp
            end
          end
        end
        result
      end

      # @param [Array<String>] values
      # @param [Array<String>] formatters
      def self.formatValues(values, formatters)
        results = []
        formatters.each do |formatter|
          # 如果是数字的话
          if formatter.is_a?(Integer)
            results << values[formatter]
            next
          end

          # @type [Hash<Integer => Integer>]
          params = {} #下标 数组
          # @type [Hash<Integer => String>]
          methods = {} #方法 数组

          splits     = self.partition_all(formatter)
          split_hash = {}
          splits.each_index do |index|
            split = splits[index]
            # 保存到 `hash` 内
            split_hash[index] = split
            if split.match?(/^:[a-zA-Z0-9_]+/)
              # 判断是不是满足初始条件
              if split.match?(/^:[0-9]+/)
                value_index   = split.match(/[0-9]+/)[0].to_i
                params[index] = values[value_index]
              else
                methods[index] = split
              end
            end
          end

          result = ""
          if methods.empty?
            splits.each_index do |index|
              if params.has_key?(index)
                result += params[index]
              else
                result += splits[index]
              end
            end
          else
            methods.keys.sort.reverse_each do |index|
              param_count  = methods[index].match(/[0-9]/)[0].to_i
              method_match = methods[index].match(/[a-zA-Z]+/).to_s
              method       = self.method(method_match)
              args         = []
              (1..param_count).each do |i|
                if params.include?(index + i)
                  args[i - 1] = params.delete(index + i) # 在对应位置上删掉该参数
                end
                if methods.include?(index + i)
                  args[i - 1] = methods.delete(index + i) # 在对应位置上删掉该参数
                end
                split_hash.delete(index + i)
              end
              methods[index] = method.call(*args)
            end
            split_hash.keys.sort.each do |index|
              if methods.has_key?(index)
                result += methods[index].to_s
              else
                result += split_hash[index]
              end
            end
          end
          results << result
        end
        results
      end
    end
  end
end