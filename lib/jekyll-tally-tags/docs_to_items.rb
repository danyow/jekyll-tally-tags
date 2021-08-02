# frozen_string_literal: true

require "jekyll"

module Jekyll
  module TallyTags
    class DocsToItems
      # @param [Site] site
      def self.read(site)
        templates = Utils.get_templates(site.config)
        return unless templates
        date_hash = insert_to_date_hash(templates, site.posts.docs)
        # 排序
        date_hash.sort_by { |a, b| a }
        items = read_csv(date_hash, templates)
        items = combine_tags(items, site)
        create_items(items, site)
      end

      # @param [Array<Hash{String => Object}>] items
      # @param [Site] site
      def self.create_items(items, site)
        item_objects = []
        items.each do |item|
          item_objects << Item.new(item, site)
        end
        site.posts.docs += item_objects
      end

      # @param [Array<Hash>] items
      # @param [Site] site
      def self.combine_tags(items, site)
        configs = site.config.fetch(TALLY, {})
        return nil unless configs && !configs.empty?
        if configs[COMBINE] && configs[COMBINE].is_a?(Array)
          configs[COMBINE].each do |config|
            find  = config[FIND]
            to    = config[TO]
            deep  = config[DEEP]
            finds = []
            items.each do |item|
              if item.keys.include?(find)
                # 找到所有 `key`
                finds += item[find]
              end
            end
            finds.uniq!
            if finds.size >= 2
              items.each { |item| item[to] = [] }
              combines = Utils.combine_tags(finds, deep)
              Utils.link_combines(combines, items, find, to)
            end
          end
        end
        items
      end

      # @param [Hash{Date => Hash{String => Array<String>}}] date_hash
      # @param [Hash{String => Hash}] templates
      # @return [Array[Hash{String => Object}]]
      def self.read_csv(date_hash, templates)
        items = []
        date_hash.each do |date, hash|
          hash.each do |temp, csv_list|
            keys = nil
            csv_list.each_with_index do |csv, index|
              # 正则处理 把",,,"这样的 分割成" ,  ,  , "
              csv.gsub!(/[，|,|\s]+/, " , ")
              # lstrip rstrip 去掉前后空格
              values = csv.split(',').each(&:lstrip!).each(&:rstrip!)
              if !keys && index == 0
                keys = values
                next
              end
              dates       = {
                DATES => date.to_s,
                YEAR  => date.strftime("%Y"),
                MONTH => date.strftime("%m"),
                DAY   => date.strftime("%d"),
                WEEKS => date.strftime("%W"),
                WEEK  => date.strftime("%w"),
              }
              dates_array = {}
              dates.each { |k, v| dates_array[k] = [v] }
              item = {
                ID            => items.size,
                PERMALINK     => "/#{ID}/#{items.size}",
                SLUG          => dates[DATES],
                DATE          => date.to_time,
                TEMPLATE      => temp,
                KEYS          => keys,
                KEYS_EXTEND   => dates.keys + keys,
                VALUES        => values,
                VALUES_EXTEND => dates.values + values,
                LAYOUT        => DEFAULT
              }.merge(dates_array)

              # 附加内容
              templates[temp].keep_if { |k, _| k != KEYS }.each do |key, formatters|
                item[key] = Utils.format_values(values, formatters)
              end
              items << item
            end
          end
        end
        items
      end

      # @example 转为下面形式
      # ``` yml
      # 2001-01-01:
      #   - template_key:
      #     - A B C D E F G
      #     - a b c d e f g
      # ```
      # @param [Hash{String => Hash}] templates
      # @param [Array<Document>] docs
      # @return [Hash{Date => Hash}]
      def self.insert_to_date_hash(templates, docs)
        date_hash = Hash.new { |h, k| h[k] = {} }
        docs.each do |doc|
          need_delete = false
          # 找出 第一层就是模板的
          items = doc.data.select { |k, _| templates.keys.include?(k) }
          # 合并到第二层去
          Utils.inner_merge(date_hash, doc.date.to_date, items)
          # 把所有的日期合并到一起
          doc.data.each do |key, value|
            if key.is_a?(Date)
              need_delete = true
              Utils.inner_merge(date_hash, key.to_date, value)
            end
          end
          # 这个文档可以被处理
          if need_delete || items
            docs.delete(doc)
          end
        end
        # 把模板内自带有 `keys` 的加入进来
        date_hash.each do |date, csv_list|
          date_hash[date] = {}
          csv_list.each do |csv|
            # lstrip rstrip 去掉前后空格
            values = csv.gsub(/[，|,|\s]+/, " , ").split(',').each(&:lstrip!).each(&:rstrip!)
            temp_key = values[0]
            if !date_hash[date][temp_key]
              date_hash[date][temp_key] = [csv]
            end
            if templates[temp_key][KEYS]
              date_hash[date][temp_key].insert(0, templates[temp_key][KEYS].join(" "))
            end
          end
        end
        date_hash
      end
    end
  end
end