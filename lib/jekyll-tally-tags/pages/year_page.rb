module Jekyll
  module TallyTags



    class YearPage < TallyTags::BasePage

      def get_content
        docs_to_content(get_docs)
      end

      # @param [Array<Document>] docs
      def docs_to_content(docs)
        yaml_mode     = true
        md_table_mode = true
        dates         = docs.collect { |doc| doc.data[SLUG] }.uniq
        align         = yaml_mode ? "" : ":----:"
        sep           = yaml_mode ? " " : " | "
        yml_temp_hash = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = { VALUES => [], MD_URL => [] } } }
        dates.each do |date|
          # 找到当前遍历的 符合 `date` 的所有 `docs`
          docs.find_all { |doc| doc.data[SLUG] == date }.each do |doc|
            template_key = doc.data[TEMPLATE]
            keys         = doc.data[CONTENTS].map { |hash| hash[KEY] }
            values       = doc.data[CONTENTS].map { |hash| hash[VALUE] }
            urls         = doc.data[CONTENTS].map { |hash| hash[MD_URL] ? hash[MD_URL] : hash[VALUE] }
            yml_temp_hash[date][{ template_key => keys }][VALUES] << values
            yml_temp_hash[date][{ template_key => keys }][MD_URL] << urls
          end
          # 计算 对齐空格数
          yml_temp_hash[date].each do |temp_keys, hash|
            values_list = hash[VALUES]
            lengths     = []
            keys        = temp_keys.values[0]
            keys.each_index do |index|
              # k_length       = get_length(keys[index])
              v_max          = values_list.collect() { |values| values[index] }.max_by() { |value| get_length(value) }
              lengths[index] = [get_length(v_max), get_length(align)].max()
            end
            yml_temp_hash[date][temp_keys][MAX_LENGTH] = lengths
          end
        end
        content = ""
        if yaml_mode
          content += "```yml\n"
          yml_temp_hash.keys.reverse_each do |date|
            content        += "#{date}:\n"
            templates_hash = yml_temp_hash[date]
            templates_hash.each_key do |temp_keys|
              temp    = temp_keys.keys[0]
              # content += "  #{temp}:\n"
              keys    = temp_keys.values[0]
              hash    = templates_hash[temp_keys]
              lengths = hash[MAX_LENGTH]
              # content += "    - #{center_values(keys, lengths, sep)}\n"
              hash[VALUES].each_index do |index|
                values  = hash[VALUES][index]
                content += "  - #{center_values(values, lengths, sep)}\n"
              end
              # content += "\n"
            end
            content += "\n"
          end
          content += "```"
        end
        content
      end

    end
  end
end