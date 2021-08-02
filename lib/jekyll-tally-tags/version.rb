# frozen_string_literal: true

require "jekyll"

module Jekyll
  module TallyTags

    VERSION = "0.1.3"

    # Hooks
    NO_NAME    = %r!^(?>.+/)*?(\d{2,4}-\d{1,2}-\d{1,2})(-([^/]*))?(\.[^.]+)$!.freeze
    YEAR       = "year".freeze
    MONTH      = "month".freeze
    DAY        = "day".freeze
    WEEKS      = "weeks".freeze
    WEEK       = "week".freeze
    DATE_HASH  = {
      YEAR  => "%Y".freeze,
      MONTH => "%m".freeze,
      WEEKS => "%W".freeze,
      WEEK  => "%w".freeze,
      DAY   => "%d".freeze,
    }
    WEEK_VALUE = [
      "周日".freeze,
      "周一".freeze,
      "周二".freeze,
      "周三".freeze,
      "周四".freeze,
      "周五".freeze,
      "周六".freeze,
    ]
    # Config
    TALLY         = "tally".freeze
    COMBINE       = 'combine'.freeze
    DEFAULT       = 'default'.freeze
    FIND          = 'find'.freeze
    TO            = 'to'.freeze
    DEEP          = 'deep'.freeze
    TEMPLATES     = 'templates'.freeze
    TEMPLATE      = 'template'.freeze
    KEY           = 'key'.freeze
    KEYS          = 'keys'.freeze
    VALUE         = 'value'.freeze
    VALUES        = 'values'.freeze
    ID            = 'id'.freeze
    PERMALINK     = "permalink".freeze
    PERMALINKS    = "permalinks".freeze
    DATE          = 'date'.freeze
    DATE_KEY      = 'DATE'.freeze
    DATES         = 'date_str'.freeze
    SLUG          = 'slug'.freeze
    LAYOUT        = 'layout'.freeze
    LAYOUTS       = 'layouts'.freeze
    KEYS_EXTEND   = 'keys_extend'.freeze
    VALUES_EXTEND = 'values_extend'.freeze
    #
    CLASSIFY      = 'classify'.freeze
    PAGES         = 'pages'.freeze
    ENABLED       = "enabled".freeze
    ALL           = "all".freeze
    COUNT         = 'count'.freeze
    TITLE         = 'title'.freeze
    TAG           = 'tag'.freeze
    MAX_LENGTH    = 'max_length'.freeze
    SYMBOL        = 'symbol'.freeze
    MD_URL        = 'md_url'.freeze
    DATE_CONTENTS = 'date_contents'.freeze
    DATE_TITLE    = 'date_title'.freeze
    CONTENTS      = 'contents'.freeze
  end
end