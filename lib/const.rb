# frozen_string_literal: true

# Const モジュール
module Const
  READLINE_HIST_FILE  = './data/.readline_history'
  PRELUDE_FILE        = './data/prelude.eme'
  EMEHCS2_VERSION     = 'emehcs2 version 0.1.0'
  EMEHCS2_FUNC_TABLE  = {
    'if'     => :my_if,
    '=='     => :eq,
    '+'      => :plus,

    '-'      => :minus,
    '*'      => :mul,
    '/'      => :div,
    'mod'    => :mod,
    '<'      => :lt,
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

  ERROR_MESSAGES = {
    insufficient_args: '引数が不足しています',
    unexpected_type:   '予期しない型'
  }.freeze

  # pop_raise
  def pop_raise = (pr = @stack.pop; raise ERROR_MESSAGES[:insufficient_args] if pr.nil?; pr)
  # func?
  def func?(x)  = x.is_a?(Array) && x.last != :q

  # 遅延評価
  class Delay
    def initialize(&fn)
      @func = fn
    end

    def force
      @func.call
    end

    def self.trcall(value)
      value = value.force while value.is_a?(Delay)
      value
    end
  end

  # 末尾再帰をスタックオーバーフローせずに実行する
  class Trcall
    alias foo eval
    def initialize(name)
      @first = true
      foo <<"DEF"
    def #{name}(*args)
      if @first
        @first = false
        value = super(*args)
        while value.instance_of?(Proc)
          value = value.call
        end
        @first = true
        value
      else
        proc { super(*args) }
      end
    end
DEF
    end
  end

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
