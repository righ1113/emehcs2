# frozen_string_literal: true

# ・以下は1回だけおこなう
# rbenv で Ruby 3.3.5(じゃなくてもいい) を入れる
# $ gem install bundler
# $ cd emehcs2
# $ bundle install --path=vendor/bundle

# ・実行方法
# $ cd emehcs2
# $ bundle exec ruby emehcs2.rb
# > [ctrl]+D か exit で終了

# require 'time'
require './lib/const'
# require './lib/parse2_core'
# require './lib/repl'

# EmehcsBase2 クラス
class EmehcsBase2
  include Const

  def initialize
    @env   = {}
    @stack = []
  end

  # abstract_method
  def read(str)
    raise NotImplementedError, 'Subclasses must implement abstract_method'
  end

  # abstract_method
  def show(expr)
    raise NotImplementedError, 'Subclasses must implement abstract_method'
  end

  # abstract_method
  def eval_(expr)
    raise NotImplementedError, 'Subclasses must implement abstract_method'
  end

  private

  def common1
    y1 = @stack.pop
    raise '引数が不足しています' if y1.nil?

    eval_ y1
  end

  def common2
    y1 = @stack.pop; y2 = @stack.pop
    raise '引数が不足しています' if y1.nil? || y2.nil?

    [eval_(y1), eval_(y2)]
  end

  def plus      = (y1, y2 = common2; @stack.push y1 + y2)
  def minus     = (y1, y2 = common2; @stack.push y2 - y1)
  def mul       = (y1, y2 = common2; @stack.push y1 * y2)
  def div       = (y1, y2 = common2; @stack.push y2 / y1)
  def mod       = (y1, y2 = common2; @stack.push y2 % y1)
  def lt        = (y1, y2 = common2; @stack.push(y2 < y1 ? 'true' : 'false'))
  def eq        = (y1, y2 = common2; @stack.push(y2 == y1 ? 'true' : 'false'))
  def s_append  = (y1, y2 = common2; @stack.push y1[0..-3] + y2)
  def my_sample = (y1 = common1; @stack.push y1[0..-2].sample)
  def error     = (y1 = common1; @stack.push raise y1.to_s)
  def car       = (y1 = common1; z = y1[0..-2]; @stack.push z[0])
  def cdr       = (y1 = common1; @stack.push y1[1..])
  def cons      = (y1, y2 = common2; @stack.push y2.unshift(y1);)
  # def my_true   = my_true_false true
  # def my_false  = my_true_false false
  # def timer1    = timer 1
  # def timer2    = timer 2
  # def cmd       = (y1 = common1; system(y1[0..-3].gsub('%', ' ')); @stack.push($?))
  # 末尾の :q を除く
  # def eval      = (y1 = common1; @code_len = 0; @stack.push parse_run(y1[0..-2]))
  # def eq2       = (y1, y2 = common2; @stack.push(run_after(y2.to_s) == run_after(y1.to_s) ? 'true' : 'false'))
end

# Emehcs2 クラス 相互に呼び合っているから、継承しかないじゃん
class Emehcs2 < EmehcsBase2
  alias read_ eval

  # Expr = Int | Sym | [Expr]
  def read(str) = read_ str.gsub(' ', ', ')
  def show(expr) = expr.to_s.gsub(',', '')
  def eval_(expr) = eval_core expr, false

  private

  # メインルーチン
  def eval_core(expr, em)
    case expr
    in Integer then (@stack.push expr; expr)
    in Symbol  then (parse_symbol expr.to_s, em; expr.to_s)
    # Array
    in []      then @stack.pop
    in [x, *xs]
      eval_core x, xs.empty?
      eval_core xs, false
    else raise '予期しない型'
    end
  end

  def parse_symbol_sub(s, em)
    if    EMEHCS2_FUNC_TABLE.key? s
      em ? send(EMEHCS2_FUNC_TABLE[s]) : @stack.push(s)             # プリミティブ関数実行1
      true
    elsif EMEHCS2_FUNC_TABLE.key? @env[s]
      em ? send(EMEHCS2_FUNC_TABLE[@env[s]]) : @stack.push(@env[s]) # プリミティブ関数実行2
      true
    else
      false
    end
  end

  def parse_symbol(s, em)
    return if parse_symbol_sub s, em

    if s[0] == '>' # 関数束縛
      @env[s[1..]] = pop_raise
      @stack.push s[1..] if em # REPL に関数名を出力する
    elsif s[0] == '=' # 変数束縛
      pop = pop_raise
      # 変数束縛のときは、Array を実行する
      @env[s[1..]] = pop.is_a?(Array) ? eval_core(pop, false) : pop
      @stack.push s[1..] if em # REPL に変数名を出力する
    elsif @env[s].is_a?(Array)
      # name が Array を参照しているときも、Array の最後だったら実行する、でなければ実行せずに積む
      if em
        @stack.push eval_core(Const.deep_copy(@env[s]), false)
      else
        @stack.push           Const.deep_copy(@env[s])
      end
    else
      @stack.push @env[s] # ふつうの name
      @stack.push s
    end
  end

  def pop_raise
    pop = @stack.pop
    raise '引数が不足しています' if pop.nil?

    pop
  end
end

# メイン関数としたもの
if __FILE__ == $PROGRAM_NAME
  # emehcs = Emehcs.new
  # repl = Repl.new emehcs
  # repl.prelude
  # repl.repl
  emehcs2 = Emehcs2.new
  p emehcs2.read('[[3 4 5] 1 2 :+]')
  p emehcs2.show([3, 4, :foo])
  p emehcs2.eval_([3, 4, :+])
end
