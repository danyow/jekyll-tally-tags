# frozen_string_literal: true

require 'jekyll'

module Jekyll
  module TallyTags
    class BasePage < Jekyll::Page
      attr_accessor :docs, :type, :slug

      ATTRIBUTES_FOR_LIQUID = %w(
        docs
        type
        title
        date
        name
        path
        url
        permalink
        sum
        content
      ).freeze
      # 初始化
      # @param [Site] site
      # @param [Hash{Symbol => String}] titles
      # @param [String] type
      # @param [Array<Document>] docs
      def initialize(site, titles, type, docs)
        @site  = site
        @docs  = docs
        @type  = type
        @title = modify_title_hash(titles)

        @config = Utils.get_permalink_config(site.config)
        @slug   = slugify_string_title

        @ext  = File.extname(relative_path)
        @path = relative_path
        @name = File.basename(relative_path, @ext)

        @data = {
          LAYOUT    => layout,
          PERMALINK => @config[PERMALINKS][type]
        }

        # avg

        @content = get_content
      end

      def get_content
        docs_to_yml(get_docs)
      end

      # @return [Array<Float>]
      def sum
        sum = []
        get_docs.each do |doc|
          if doc.data[COUNT]
            doc.data[COUNT].each_with_index do |count, index|
              sum[index] = 0 if index == 0
              sum[index] += count.to_f
            end
          end
        end
        sum
      end

      def avg
        avg   = []
        dates = @docs.collect { |t| t.date.to_date }.uniq
        sum.each_index do |index|
          avg[index] = Methods.to_f_s(sum[index] / dates.size)
        end
        avg
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

      # @param [Hash<Symbol => String, Array>]
      def modify_title_hash(titles)
        temp = {}
        titles.each do |k, v|
          if v.is_a?(Array)
            temp[k] = v.join(",")
          else
            temp[k] = v
          end
        end
        temp
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
            path = File.join(path, "index.md") if url.end_with?("/")
            path
          end
      end

      # @return [String]
      def inspect
        "#<TagsLib:Subject @type=#{@type} @title=#{@title} @data=#{@data.inspect}>"
      end

      private

      # @return [Array<Document>]
      def get_docs
        @docs
      end

      def slugify_string_title
        return unless title.is_a?(String)
        Jekyll::Utils.slugify(title, :mode => @config[SLUG_MODE])
      end

      # @param [Array<Document>] docs
      def docs_to_yml(docs)

        yaml_mode     = false
        md_table_mode = false

        # 获取里面所有的 `template keys`
        template_keys = docs.collect() { |doc| doc.data[TEMPLATE] }.uniq
        align         = yaml_mode ? "" : ":----:"
        sep           = yaml_mode ? " " : " | "
        # 初始化
        yaml_templates_hash = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = { VALUES => [], MD_URL => [] } } }
        template_keys.each do |template_key|
          # 找到当前遍历的 符合 `key` 的所有 `docs`
          template_docs = docs.find_all() { |doc| doc.data[TEMPLATE] == template_key }
          template_docs.each do |doc|
            keys = doc.data[DATE_CONTENTS].map { |hash| hash[KEY] }
            yaml_templates_hash[template_key][keys][VALUES] << doc.data[DATE_CONTENTS].map { |hash| hash[VALUE] }
            yaml_templates_hash[template_key][keys][MD_URL] << doc.data[DATE_CONTENTS].map { |hash| hash[MD_URL] ? hash[MD_URL] : hash[VALUE] }
          end
          # 计算 对齐空格数
          yaml_templates_hash[template_key].each do |keys, hash|
            values_list = hash[VALUES]
            lengths     = []
            keys.each_index do |index|
              k_length       = get_length(keys[index])
              v_max          = values_list.collect() { |values| values[index] }.max_by() { |value| get_length(value) }
              lengths[index] = [k_length, get_length(v_max), get_length(align)].max()
            end
            yaml_templates_hash[template_key][keys][MAX_LENGTH] = lengths
          end
        end

        content = ""
        if yaml_mode
          content += "```yml\n"
          yaml_templates_hash.each_key do |template_key|
            content        += "#{template_key}:\n"
            templates_hash = yaml_templates_hash[template_key]
            templates_hash.each_key do |keys|
              hash    = templates_hash[keys]
              lengths = hash[MAX_LENGTH]
              content += "  - #{center_values(keys, lengths, sep)}\n"
              hash[VALUES].each_index do |index|
                values  = hash[VALUES][index]
                content += "  - #{center_values(values, lengths, sep)}\n"
              end
              content += "\n"
            end
            content += "\n"
          end
          content += "```"
        else
          content += "```markdown\n" if md_table_mode
          yaml_templates_hash.each_key do |template_key|
            templates_hash = yaml_templates_hash[template_key]
            templates_hash.each_key do |keys|
              hash    = templates_hash[keys]
              lengths = hash[MAX_LENGTH]
              content += "#{sep}#{center_values(keys, lengths, sep)}#{sep}\n"
              content += "#{sep}#{center_values(keys.map { align }, lengths, sep)}#{sep}\n"
              hash[VALUES].each_index do |index|
                values  = md_table_mode ? hash[VALUES][index] : hash[MD_URL][index]
                content += "#{sep}#{center_values(values, lengths, sep)}#{sep}\n"
              end
              content += "\n"
            end
            content += "\n"
          end
          content += "```" if md_table_mode
        end
        content
      end

      # @param [Array<String>] values
      # @param [Array<Int>] lengths
      # @param [String] sep
      def center_values(values, lengths, sep)
        temp = Array.new(values)
        temp.each_index do |index|
          # ljust center rjust
          if temp[index]
            temp[index] = temp[index].encode('gbk').b.center(lengths[index]).force_encoding("gbk").encode("utf-8")
          else
            temp[index] = "".center(lengths[index])
          end
        end
        temp.join(sep)
      end

      # @param [Array<String>] values
      # @param [Array<Int>] lengths
      # @param [String] sep
      # @param [Array<String>] permalinks
      def center_values_url(values, lengths, sep, permalinks)
        temp = Array.new(values)
        temp.each_index do |index|
          # ljust center rjust
          temp[index] = temp[index].encode('gbk').b.center(lengths[index]).force_encoding("gbk").encode("utf-8")
        end
        temp.each_with_index do |temp, index|
          url         = "[#{values[index]}](#{permalinks[index]})"
          temp[index] = temp.gsub(values[index], url)
        end
        temp.join(sep)
      end

      # @param [String] value
      def get_length(value)
        value ? value.encode('gbk').b.length : 0
      end
    end
  end
end