# frozen_string_literal: true

require "jekyll"

module Jekyll
  module TallyTags
    class Utils
      # 把配置变成数组配置
      # @param [Array, Object]
      # @return [Array]
      def self.to_array(single_or_array, default)
        return default unless single_or_array
        if single_or_array.is_a?(Array)
          single_or_array
        else
          [single_or_array]
        end
      end

      # @param [Hash<Object, Hash<Array>>] hash
      # @param [Object] key
      # @param [Hash<Array>] inner_hash
      def self.inner_merge(hash, key, inner_hash)
        if hash.include?(key)
          hash[key].merge!(inner_hash) { |_, o, n| o + n }
        else
          hash[key] = inner_hash
        end
      end

      # @param [Array<String>] values
      # @param [Array<String>] formatters
      def self.format_values(values, formatters)
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
              method       = Methods.method(method_match)
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
                if params.has_key?(index)
                  result += params[index]
                else
                  result += split_hash[index]
                end
              end
            end
          end
          results << result
        end
        results
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
            unless temp.empty?
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

      # @param [Array<Array<String>>] combines
      # @param [Array<Hash>] items
      # @param [String] find
      # @param [String] to
      def self.link_combines(combines, items, find, to)
        combines.each do |combine|
          items.each do |item|
            if item[find] & combine
              unless item[to]
                item[to] = []
              end
              unless item[to].include?(combine)
                item[to] << combine
              end
            end
          end
        end
      end

      # @param [Array<String>] items 原始数据
      # @param [Integer, Array<Integer>] deep_key 合并类型
      # @return [Array<Array<String>>]
      def self.combine_tags(items, deep_key)
        hash    = {}
        is_deep = false
        if items.size > 2
          deep_key = ALL unless deep_key
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
        unless deep_items
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

      # @param [Configuration] site_config
      # @param [String] field
      def self.get_tally_config(site_config, field = nil)
        config = site_config[TALLY]
        if field
          config ? config[field] : nil
        else
          config
        end
      end

      # 获取 `Tally` 里模板配置
      # @param [Site] site
      # @return [Hash{String => Hash{String => Hash}}]
      def self.get_templates(site_config)
        configs = site_config[TALLY]
        return nil unless configs && !configs.empty?
        # 然后获取默认配置 没有也是可以的
        # @type [Hash<String => Array<Integer, String>>]
        default_template = configs[DEFAULT]

        # 初始化默认的模板
        if default_template
          default_template.collect { |t| Utils.to_array(t, nil) }
        end

        # 先判断有没有对应的配置
        # @type [Hash<String => Array<Integer, String>>]
        templates = configs[TEMPLATES]
        # 必须有模板才可以解析
        return {
          DEFAULT => default_template
        } unless templates && !templates.empty?

        # 与默认模板合并
        templates.each_key do |template_key|
          template = templates[template_key].merge!(default_template)
          template.each_key do |key|
            template[key] = Utils.to_array(template[key], default_template[key])
          end
        end
        templates
      end

      # @param [Configuration] site_config
      # @param [String] field
      def self.get_permalink_config(site_config, field = nil)
        config = site_config[CLASSIFY]
        if field
          config ? config[field] : nil
        else
          config
        end
      end
    end
  end
end