# frozen_string_literal: true

require "jekyll"

module Jekyll
  module TallyTags
    class Item < Document
      # @param [Hash] item
      # @param [Site] site
      def initialize(item, site)
        @data       = item
        @site       = site
        @path       = "#{site.collections_path}/_posts/#{item[DATE].to_date.to_s}-#{item[ID]}.md"
        @extname    = File.extname(@path)
        @collection = site.posts
        @type       = @collection.label.to_sym

        @has_yaml_header = nil

        if draft?
          categories_from_path("_drafts")
        else
          categories_from_path(collection.relative_directory)
        end

        data.default_proc = proc do |_, key|
          site.frontmatter_defaults.find(relative_path, type, key)
        end

        # 加入 link
        permalinks       = Utils.get_permalink_config(site.config, PERMALINKS)
        item[PERMALINKS] = Hash.new { |h, k| h[k] = [] }
        permalinks.each do |key, permalink|
          permalink.scan(/:(\w+)/) do |match_data|
            match = match_data[0]
            if item.keys.include?(match)
              item[match].each_with_index do |t, index|
                permalink                    = item[PERMALINKS][key][index] ? item[PERMALINKS][key][index] : String.new(permalink)
                item[PERMALINKS][key][index] = permalink.gsub(":#{match}", t.is_a?(Array) ? t.join('-') : t)
              end
            end
          end
        end
        # 获取当前配置
        template = Utils.get_templates(site.config)[item[TEMPLATE]]
        template = {}.merge(template)
        template.keep_if do |key, _|
          key != TITLE && key != COUNT
        end
        # 分析内容
        contents = []
        item[KEYS].each_with_index do |key, index|
          contents[index] = {
            KEY   => key,
            VALUE => item[VALUES][index],
          }
          template.each do |tag, indexes|
            if indexes.include? index
              contents[index][SYMBOL] = tag
              # FIXME: 这里乱序就会出问题
              contents[index][PERMALINK] = item[PERMALINKS][tag].delete_at(0)
              contents[index][MD_URL]    = to_url(contents[index][VALUE], contents[index][PERMALINK])
            end
          end
        end

        year       = item[YEAR][0]
        month      = item[MONTH][0]
        day        = item[DAY][0]
        week       = item[WEEK][0].to_i
        permalinks = item[PERMALINKS]
        # 加入时间
        date_hash      = {
          KEY    => "日期",
          VALUE  => "#{year}/#{month}/#{day}-#{WEEK_VALUE[week]}",
          SYMBOL => DATE,
          MD_URL => "#{to_url(year, permalinks[YEAR][0])}/#{to_url(month, permalinks[MONTH][0])}/#{to_url(day, permalinks[DAY][0])}-#{to_url(WEEK_VALUE[week], permalinks[WEEK][0])}"
        }
        item[CONTENTS] = [] + contents
        contents.insert(0, date_hash)
        item[DATE_TITLE]    = date_hash
        item[DATE_CONTENTS] = contents
      end

      def to_url(text, permalink)
        "[#{text}](#{permalink})"
      end
    end
  end
end