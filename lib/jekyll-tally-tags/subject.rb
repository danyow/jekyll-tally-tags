# frozen_string_literal: true

require 'jekyll'

module Jekyll
  module TallyTags
    class Subject < Jekyll::Page
      attr_accessor :docs, :type, :slug

      ATTRIBUTES_FOR_LIQUID = %w(
        docs
        filters
        type
        title
        date
        name
        path
        url
        permalink
        sum
      ).freeze

      # 初始化
      # @param [Site] site
      # @param [Hash{Symbol => String}] titles
      # @param [String] type
      # @param [Array<String>] filters
      # @param [Array<Document>] docs
      def initialize(site, titles, type, filters, docs)
        @site    = site
        @docs    = docs
        @filters = filters
        @type    = type
        @title   = titles
        @config  = site.config[CLASSIFY]
        @slug    = slugify_string_title

        @ext  = File.extname(relative_path)
        @path = relative_path
        @name = File.basename(relative_path, @ext)

        @data    = {
          LAYOUT    => layout,
          PERMALINK => @config[PERMALINKS][type]
        }
        @content = ""

      end

      # @return [Array<Float>]
      def sum
        sum = []
        @docs.each do |doc|
          (0..doc[COUNT].size - 1).each do |index|
            count = doc[COUNT][index].to_f
            if !sum[index]
              sum[index] = 0
            end
            sum[index] = sum[index] + count
          end
        end
        sum
      end

      # @return [String]
      def template
        @config.dig(PERMALINKS, type)
      end

      # @return [String]
      def layout
        @config.dig(LAYOUTS, type) || @config[LAYOUT]
      end

      # @return [Hash{ String => String}] eg: {:categories => "ruby", :title => "something"}
      def url_placeholders
        if @title.is_a? Hash
          @title.merge(:type => @type)
        else
          { :name => @slug, :type => @type }
        end
      end

      # @return [String]
      def url
        u = @url ||= URL.new(
          :template     => template,
          :placeholders => url_placeholders,
          :permalink    => nil
        ).to_s
      rescue ArgumentError
        raise ArgumentError, "提供的模板 \"#{template}\" 无效."
      end

      def filters
        @filters
      end

      # @return [String]
      def permalink
        data.is_a?(Hash) && data[PERMALINK]
      end

      # @return [String]
      def title
        @title if @title.is_a?(String)
      end

      # @return [Date]
      def date
        # if @title.is_a?(Hash)
        #   args = @title.values.map(&:to_i)
        #   Date.new(*args)
        # end
        # TODO: 修复日期
        "2011/01/11"
      end

      # @return [String]
      def relative_path
        @relative_path ||=
          begin
            path = URL.unescape_path(url).gsub(%r!^/!, "")
            path = File.join(path, INDEX_HTML) if url.end_with?("/")
            path
          end
      end

      # @return [String]
      def inspect
        "#<TagsLib:Subject @type=#{@type} @title=#{@title} @data=#{@data.inspect}>"
      end

      private

      def slugify_string_title
        return unless title.is_a?(String)
        Utils.slugify(title, :mode => @config[SLUG_MODE])
      end

    end
  end
end