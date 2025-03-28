# frozen_string_literal: true

# Const モジュール
module Const
  READLINE_HIST_FILE  = './data/.readline_history'
  PRELUDE_FILE        = './data/prelude.eme'
  EMEHCS2_VERSION     = 'emehcs2 version 0.1.0'
  EMEHCS2_FUNC_TABLE1 = {
    'error'  => :error,
    'car'    => :car,
    'cdr'    => :cdr,
    'chr'    => :chr,
    'length' => :length,
    'sample' => :my_sample
  }.freeze
  EMEHCS2_FUNC_TABLE2 = {
    # 'if'     => :my_if,
    '=='     => :eq,
    '+'      => :plus,

    '!='     => :ne,
    '-'      => :minus,
    # '*'      => :mul,
    # '/'      => :div,
    # 'mod'    => :mod,
    '<'      => :lt,
    'cons'   => :cons,
    # 's.++'   => :s_append,
    '!!'     => :index
  }.freeze

  ERROR_MESSAGES = {
    insufficient_args: '引数が不足しています',
    unexpected_type:   '予期しない型'
  }.freeze

  def error(y1)       = @stack.push raise y1.to_s
  def car(y1)         = @stack.push y1[0]
  def cdr(y1)         = @stack.push y1[1..]
  def chr(y1)         = (z = y1 % 256; @stack.push z.chr)
  def length(y1)      = @stack.push y1.length
  def my_sample(y1)   = @stack.push y1[0..-2].sample

  def eq(y1, y2)      = @stack.push y2 == y1 ? 'true' : 'false'
  def plus(y1, y2)    = @stack.push y1 + y2
  def ne(y1, y2)      = @stack.push y2 != y1 ? 'true' : 'false'
  def minus(y1, y2)   = @stack.push y2 - y1
  def lt(y1, y2)      = @stack.push y2 < y1 ? 'true' : 'false'
  def cons(y1, y2)    = @stack.push [y1] + y2

  def index(y1, y2)
    # puts "!!: #{y2}, #{y1}"
    ret = y2[y1]
    @stack.push ret.is_a?(Integer) ? ret : ret.to_sym
  end

  # pop_raise
  def pop_raise = (pr = @stack.pop; raise ERROR_MESSAGES[:insufficient_args] if pr.nil?; pr)
  # func?
  def func?(x)  = x.is_a?(Array) && x.last != :q

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
