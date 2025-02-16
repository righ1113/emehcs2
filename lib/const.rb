# frozen_string_literal: true

# Const モジュール
module Const
  READLINE_HIST_FILE  = './data/.readline_history'
  PRELUDE_FILE        = './data/prelude.eme'
  EMEHCS2_VERSION     = 'emehcs2 version 0.1.0'
  EMEHCS2_FUNC_TABLE  = {
    '+'      => :plus,
    '-'      => :minus,
    '*'      => :mul,
    '/'      => :div,
    'mod'    => :mod,
    '<'      => :lt,
    '=='     => :eq,
    'true'   => :my_true,
    'false'  => :my_false,
    'cons'   => :cons,
    's.++'   => :s_append,
    'sample' => :my_sample,
    'error'  => :error,
    'car'    => :car,
    'cdr'    => :cdr,
    'timer1' => :timer1,
    'timer2' => :timer2,
    'cmd'    => :cmd,
    # 'list'   => :list は直接呼び出す
    'eval'   => :eval,
    'eq2'    => :eq2
  }.freeze

  # Const クラス
  class Const
    def self.deep_copy(arr)
      Marshal.load(Marshal.dump(arr))
    end

    # このようにして assert を使うことができます
    def self.assert(cond1, cond2, message = 'Assertion failed')
      raise "#{cond1} #{cond2} <#{message}>" unless cond1 == cond2
    end
  end
end
