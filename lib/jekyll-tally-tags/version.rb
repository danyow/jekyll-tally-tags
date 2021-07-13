# frozen_string_literal: true

module Jekyll
  module TallyTags
    VERSION = "0.1.0"
    # 字段
    CLASSIFY    = "classify".freeze
    SUBJECTS    = "subjects".freeze
    SUBJECT     = "subject".freeze
    CLASS       = "class".freeze
    CLASSES     = "classes".freeze
    YEAR        = "year".freeze
    MONTH       = "month".freeze
    DAY         = "day".freeze
    WEEK        = "week".freeze
    READ_METHOD = "read_".freeze
    ENABLED     = "enabled".freeze
    ALL         = "all".freeze
    # Subject
    SLUG_MODE  = "slug_mode".freeze
    INDEX_HTML = "index.html".freeze
    LAYOUT     = "layout".freeze
    LAYOUTS    = "layouts".freeze
    PERMALINK  = "permalink".freeze
    PERMALINKS = "permalinks".freeze
    NUMBER     = "number".freeze
    TALLY      = "tally".freeze
    KEYS       = "keys".freeze
    # Hooks
    NO_NAME = %r!^(?>.+/)*?(\d{2,4}-\d{1,2}-\d{1,2})(-([^/]*))?(\.[^.]+)$!.freeze
    ###
    COUNTER   = 'counter'.freeze # 总配置字段
    TEMPLATES = 'templates'.freeze # 对应的 key 表
    KEY       = "key".freeze
    UNIT      = 'unit'.freeze # 表内 计算后的单位
    NAME      = 'name'.freeze # key 表的名称
    COUNT     = 'count'.freeze # 需要计算的下标
    CATEGORY  = 'category'.freeze # 分类下标
    TAG       = 'tag'.freeze # 标签下标
    TAGS      = 'tags'.freeze # 需要分类的下标
    FORMATTER = 'formatter'.freeze
    INT       = 'int'.freeze

    # Doc
    ID      = 'id'.freeze
    DATA    = 'data'.freeze
    TITLE   = 'title'.freeze
    COMBINE = 'combine'.freeze
    DEFAULT = 'default'.freeze
    FIND    = 'find'.freeze
    TO      = 'to'.freeze
    DEEP    = 'deep'.freeze
  end
end
