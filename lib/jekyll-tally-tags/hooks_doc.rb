module Jekyll
  module TallyTags

    Jekyll::Hooks.register :site, :after_init do |_|
      # 修改正则让 `2021-01-01.md` 就算无后缀也可读
      old = Jekyll::Document::DATE_FILENAME_MATCHER
      new = NO_NAME
      if old != new
        Jekyll::Document::DATE_FILENAME_MATCHER = new
      end
    end

    Jekyll::Hooks.register :site, :post_read do |site|

      # 首先获取所有在 `tally` 内 `list` 的值
      tally_configs = site.config.fetch(TALLY, {})
      next unless tally_configs && !tally_configs.empty?
      # 然后获取默认配置 没有也是可以的
      # @type [Hash<String => Array<Integer, String>>]
      default_template = tally_configs[DEFAULT]

      if default_template
        # 初始化默认的模板
        default_template.each_key do |key|
          default_template[key] = Counter.to_array(default_template[key], nil)
        end
      end

      # 先判断有没有对应的配置
      # @type [Hash<String => Array<Integer, String>>]
      templates = tally_configs[TEMPLATES]
      # 必须有模板才可以解析
      next unless templates && !templates.empty?

      # @type [Array<Document>]
      docs = site.posts.docs # 文章里的文档 (也就是 `yaml`)
      id   = 0 # id

      no_scan_docs = [] # 无法扫描的文档
      scanned_docs = [] # 创建新的文档

      # 先遍历模板
      templates.each_key do |template_key|
        template = templates[template_key]
        template.each_key do |key|
          # 依据默认模板生成新的模板
          template[key] = Counter.to_array(template[key], default_template[key])
        end
      end

      # 后便利文档
      docs.each do |doc|
        # 判断这个文档里面有没有对应的 `template`
        doc_has_template = doc.data.keys & templates.keys
        if !doc_has_template || doc_has_template.empty?
          no_scan_docs << doc
          next
        end

        doc_has_template.each do |template_key|
          csv_list = doc[template_key]
          template = templates[template_key]
          # 下一步 如果 有值 且 不为空
          next unless csv_list && !csv_list.empty?

          # 如果不是数组的话
          if !csv_list.is_a?(Array)
            Jekyll.logger.warn(template_key, "#{doc.path}里的数据不为数组, 将不解析该字段")
            next
          end

          keys = []
          csv_list.each_index do |csv_index|
            csv = csv_list[csv_index]
            # 正则处理 把",,,"这样的 分割成" ,  ,  , "
            csv.gsub!(/[，|,|\s]+?/, " , ")
            # lstrip rstrip 去掉前后空格
            # @type [Array<String>]
            values = csv.split(',').each(&:lstrip!).each(&:rstrip!)
            # 判断有没有 `keys` 如果没有 第一行就作为 `keys` 因为第一行作为 `keys` 就是像极了 `csv`
            if (!template[KEYS] || template[KEYS].empty?) && csv_index == 0
              keys = values
              next
            end
            # 初始化数据
            datum = { ID => id, PERMALINK => "/#{ID}/#{id}" }
            # 对当前 `template` 所有 `key` 遍历
            template.each_key do |key|
              datum[key] = Counter.formatValues(values, template[key])
            end

            # 对 `values` 所有 内容 遍历
            values.each_index do |index|
              datum[keys[index]] = values[index]
            end

            # 可能会死循环 `Document.new` 还会发消息
            # TODO: 后续 采用 `Document` 子类
            new_doc = Document.new(doc.path, site: site, collection: site.posts)
            new_doc.data.replace(doc.data)
            new_doc.data[DATA] = {}
            # 重新赋值
            datum.each_key do |key|
              Counter.set_doc_data(new_doc, key, datum[key])
            end
            scanned_docs << new_doc
            id += 1
          end
        end
      end
      # @type [Array<Document>]
      all_docs = no_scan_docs + scanned_docs
      # 判断是不是需要 开启组合模式
      combine_configs = tally_configs[COMBINE]
      if combine_configs && combine_configs.is_a?(Array)
        combine_configs.each do |config|
          find_key      = config[FIND]
          combine_key   = config[TO]
          deep_key      = config[DEEP]
          all_find_keys = []
          all_docs.each do |doc|
            doc.data[combine_key] = []
            # 找到所有 `key`
            all_find_keys += doc.data[find_key]
          end
          merges = Counter.merge_all(all_find_keys.uniq!, deep_key)
          Counter.combine_merge_list(merges, all_docs, find_key, combine_key)
        end
      end

      site.posts.docs = all_docs
    end
  end
end