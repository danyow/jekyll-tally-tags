# frozen_string_literal: true

require "jekyll"
require "jekyll-tally-tags/version"

module Jekyll
  module TallyTags

    autoload :DocsToItems, "jekyll-tally-tags/docs_to_items"
    autoload :Item, "jekyll-tally-tags/item"
    autoload :ItemsToPage, "jekyll-tally-tags/items_to_page"
    autoload :Methods, "jekyll-tally-tags/methods"
    autoload :Utils, "jekyll-tally-tags/utils"
    autoload :BasePage, "jekyll-tally-tags/pages/base_page"
    autoload :DayPage, "jekyll-tally-tags/pages/day_page"
    autoload :MonthPage, "jekyll-tally-tags/pages/month_page"
    autoload :MultiplePage, "jekyll-tally-tags/pages/multiple_page"
    autoload :SinglePage, "jekyll-tally-tags/pages/single_page"
    autoload :WeeksPage, "jekyll-tally-tags/pages/weeks_page"
    autoload :WeekPage, "jekyll-tally-tags/pages/week_page"
    autoload :YearPage, "jekyll-tally-tags/pages/year_page"

    DEBUG = false

    Jekyll::Hooks.register :site, :after_init do |_|
      puts 'site   after_init 在网站初始化时，但是在设置和渲染之前，适合用来修改网站的配置项' if DEBUG
      # 修改正则让 `2021-01-01.md` 就算无后缀也可读
      Jekyll::Document::DATE_FILENAME_MATCHER = NO_NAME
    end

    Jekyll::Hooks.register :site, :post_read do |site|
      puts 'site   post_read 在网站数据从磁盘中读取并加载之后' if DEBUG
      DocsToItems.read(site)
    end

    class ItemsToPage < Jekyll::Generator
      safe true
      # @param [Configuration] config
      def initialize(config = nil)
        @config  = Utils.get_permalink_config(config)
        @enabled = Utils.get_permalink_config(config, ENABLED)
      end

      # @param [Site] site
      def generate(site)
        # 判断是否为空
        return if @config.nil?
        # 开始赋值
        @site  = site
        @posts = site.posts
        @pages = []

        read_all(@config[PERMALINKS], @site.posts.docs)
        # 把所有的拼接到到 `pages` 里面
        @site.pages.concat(@pages)
        # 配置里面也放一份
        @site.config[PAGES] = @pages
      end

      # @param [Hash{String => String}] permalinks
      # @param [Array<Document>] scan_docs
      def read_all(permalinks, scan_docs)
        permalinks.each do |key, permalink|
          # 判断 链接是否包含 :xxx :(\w+)
          matches = []
          permalink.scan(/:(\w+)/) { |match| matches << match[0] }
          read_loop(key, {}, Array.new(scan_docs), matches, 0)
        end
      end

      # @param [String] permalink_key
      # @param [Hash{Symbol => String}] titles
      # @param [Array<Document>] docs
      # @param [Array<String>] matches
      # @param [Integer] index
      def read_loop(permalink_key, titles, docs, matches, index)
        if index > matches.size - 1
          return
        end
        match = matches[index]
        # 找到对应的 docs
        if DATE_HASH.keys.include?(match)
          docs_hash = date_to_docs_hash(docs, DATE_HASH[match])
          read_any(docs_hash, match.to_sym, permalink_key, titles, matches, index + 1)
        else
          begin
            docs_hash = tags_to_docs_hash(docs, match)
            read_any(docs_hash, match.to_sym, permalink_key, titles, matches, index + 1)
          rescue
            Jekyll.logger.warn CLASSIFY, "没有该keys ':#{match}'"
          end
        end
      end

      # @param [Hash{String => Array<Document>}] docs_hash
      # @param [Symbol] symbol
      # @param [String] permalink_key
      # @param [Hash{Symbol => String}] titles
      # @param [Array<String>] matches
      # @param [Integer] index
      def read_any(docs_hash, symbol, permalink_key, titles, matches, index)
        docs_hash.each do |key, docs|
          new_titles = titles.merge({ symbol => key })
          # 开启了该字段 同时 是匹配的最后一项的时候 写入数组
          if enabled?(permalink_key) && index == matches.size
            clz = SinglePage
            case permalink_key
            when YEAR
              clz = YearPage
            when MONTH
              clz = MonthPage
            when DAY
              clz = DayPage
            when WEEK
              clz = WeekPage
            when WEEKS
              clz = WeekPage
            end
            @pages << clz.new(@site, new_titles, permalink_key, docs.keep_if { |doc| doc.data[TEMPLATE] })
          end
          read_loop(permalink_key, new_titles, docs, matches, index)
        end
      end

      private

      # @param [String] type
      def enabled?(type)
        @enabled == true || @enabled == ALL || (@enabled.is_a?(Array) && @enabled.include?(type))
      end

      # @param [Array<Document>] docs
      # @param [String] attr
      # @return [Hash{String => Array<Document>}]
      def tags_to_docs_hash(docs, attr)
        hash = Hash.new { |h, key| h[key] = [] }
        docs.each do |doc|
          doc.data[attr]&.each { |key| hash[key] << doc }
        end
        hash.each_value { |docs| docs.sort!.reverse! }
        hash
      end

      # @param [Array<Document>] docs `yaml` 头部信息
      # @param [String] id ISO-8601
      # @return [Hash{String=>Array<Document>}]
      def date_to_docs_hash(docs, id)
        hash = Hash.new { |h, k| h[k] = [] }
        docs.each { |doc| hash[doc.date.strftime(id)] << doc }
        hash.each_value { |docs| docs.sort!.reverse! }
        hash
      end

    end

    Jekyll::Hooks.register :site, :after_reset do |_|
      puts 'site   after_reset 网站重置之后' if DEBUG
    end
    Jekyll::Hooks.register :site, :pre_render do |_|
      puts 'site   pre_render 在渲染整个网站之前' if DEBUG
    end
    Jekyll::Hooks.register :site, :post_render do |_|
      puts 'site   post_render 在渲染整个网站之后，但是在写入任何文件之前' if DEBUG
    end
    Jekyll::Hooks.register :site, :post_write do |_|
      puts 'site   post_write 在将整个网站写入磁盘之后' if DEBUG
    end
    Jekyll::Hooks.register :pages, :post_init do |_|
      puts 'pages   post_init 每次页面被初始化的时候' if DEBUG
    end
    Jekyll::Hooks.register :pages, :pre_render do |_|
      puts 'pages   pre_render 在渲染页面之前' if DEBUG
    end
    Jekyll::Hooks.register :pages, :post_render do |_|
      puts 'pages   post_render 在页面渲染之后，但是在页面写入磁盘之前' if DEBUG
    end
    Jekyll::Hooks.register :pages, :post_write do |_|
      puts 'pages   post_write 在页面写入磁盘之后' if DEBUG
    end
    Jekyll::Hooks.register :posts, :post_init do |_|
      puts 'posts   post_init 每次博客被初始化的时候' if DEBUG
    end
    Jekyll::Hooks.register :posts, :pre_render do |_|
      puts 'posts   pre_render 在博客被渲染之前' if DEBUG
    end
    Jekyll::Hooks.register :posts, :post_render do |_|
      puts 'posts   post_render 在博客渲染之后，但是在被写入磁盘之前' if DEBUG
    end
    Jekyll::Hooks.register :posts, :post_write do |_|
      puts 'posts   post_write 在博客被写入磁盘之后' if DEBUG
    end
    Jekyll::Hooks.register :documents, :post_init do |_|
      puts 'documents   post_init 每次文档被初始化的时候' if DEBUG
    end
    Jekyll::Hooks.register :documents, :pre_render do |_|
      puts 'documents   pre_render 在渲染文档之前' if DEBUG
    end
    Jekyll::Hooks.register :documents, :post_render do |_|
      puts 'documents   post_render 在渲染文档之后，但是在被写入磁盘之前' if DEBUG
    end
    Jekyll::Hooks.register :documents, :post_write do |_|
      puts 'documents   post_write 在文档被写入磁盘之后' if DEBUG
    end
  end
end