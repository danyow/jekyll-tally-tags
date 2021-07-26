# # frozen_string_literal: true
#
# require "jekyll"
#
# module Jekyll
#   module TallyTags
#
#     class ItemsToPage < Generator
#       safe true
#       # @param [Configuration] config
#       def initialize(config = nil)
#         @config  = Utils.get_permalink_config(config)
#         @enabled = Utils.get_permalink_config(config, ENABLED)
#       end
#
#       # @param [Site] site
#       def generate(site)
#         # 判断是否为空
#         return if @config.nil?
#         # 开始赋值
#         @site  = site
#         @posts = site.posts
#         @pages = []
#
#         read_all(@config[PERMALINKS], @site.posts.docs)
#         # 把所有的拼接到到 `pages` 里面
#         @site.pages.concat(@pages)
#         # 配置里面也放一份
#         @site.config[PAGES] = @pages
#       end
#
#       # @param [Hash{String => String}] permalinks
#       # @param [Array<Document>] scan_docs
#       def read_all(permalinks, scan_docs)
#         permalinks.each do |key, permalink|
#           # 判断 链接是否包含 :xxx :(\w+)
#           matches = []
#           permalink.scan(/:(\w+)/) { |match| matches << match[0] }
#           read_loop(key, {}, Array.new(scan_docs), matches, 0)
#         end
#       end
#
#       # @param [String] permalink_key
#       # @param [Hash{Symbol => String}] titles
#       # @param [Array<Document>] docs
#       # @param [Array<String>] matches
#       # @param [Integer] index
#       def read_loop(permalink_key, titles, docs, matches, index)
#         if index > matches.size - 1
#           return
#         end
#         match = matches[index]
#         # 找到对应的 docs
#         if DATE_HASH.keys.include?(match)
#           docs_hash = date_to_docs_hash(docs, DATE_HASH[match])
#           read_any(docs_hash, match.to_sym, permalink_key, titles, matches, index + 1)
#         else
#           begin
#             docs_hash = tags_to_docs_hash(docs, match)
#             read_any(docs_hash, match.to_sym, permalink_key, titles, matches, index + 1)
#           rescue
#             Jekyll.logger.warn CLASSIFY, "没有该keys ':#{match}'"
#           end
#         end
#       end
#
#       # @param [Hash{String => Array<Document>}] docs_hash
#       # @param [Symbol] symbol
#       # @param [String] permalink_key
#       # @param [Hash{Symbol => String}] titles
#       # @param [Array<String>] matches
#       # @param [Integer] index
#       def read_any(docs_hash, symbol, permalink_key, titles, matches, index)
#         docs_hash.each do |key, docs|
#           new_titles = titles.merge({ symbol => key })
#           # 开启了该字段 同时 是匹配的最后一项的时候 写入数组
#           if enabled?(permalink_key) && index == matches.size
#             clz = SinglePage
#             case permalink_key
#             when YEAR
#               clz = YearPage
#             when MONTH
#               clz = MonthPage
#             when DAY
#               clz = DayPage
#             when WEEK
#               clz = WeekPage
#             when WEEKS
#               clz = WeekPage
#             end
#             @pages << clz.new(@site, new_titles, permalink_key, docs.keep_if { |doc| doc.data[TEMPLATE] })
#           end
#           read_loop(permalink_key, new_titles, docs, matches, index)
#         end
#       end
#
#       private
#
#       # @param [String] type
#       def enabled?(type)
#         @enabled == true || @enabled == ALL || (@enabled.is_a?(Array) && @enabled.include?(type))
#       end
#
#       # @param [Array<Document>] docs
#       # @param [String] attr
#       # @return [Hash{String => Array<Document>}]
#       def tags_to_docs_hash(docs, attr)
#         hash = Hash.new { |h, key| h[key] = [] }
#         docs.each do |doc|
#           doc.data[attr]&.each { |key| hash[key] << doc }
#         end
#         hash.each_value { |docs| docs.sort!.reverse! }
#         hash
#       end
#
#       # @param [Array<Document>] docs `yaml` 头部信息
#       # @param [String] id ISO-8601
#       # @return [Hash{String=>Array<Document>}]
#       def date_to_docs_hash(docs, id)
#         hash = Hash.new { |h, k| h[k] = [] }
#         docs.each { |doc| hash[doc.date.strftime(id)] << doc }
#         hash.each_value { |docs| docs.sort!.reverse! }
#         hash
#       end
#
#     end
#   end
# end