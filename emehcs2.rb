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

  private

  def common1
    y1 = @stack.pop
    raise '引数が不足しています' if y1.nil?

    eval_core [y1]
  end

  def common2
    y1 = @stack.pop; y2 = @stack.pop
    raise '引数が不足しています' if y1.nil? || y2.nil?

    [eval_core([y1]), eval_core([y2])]
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
  def run(str) = (@stack = []; show eval_core read str)

  private

  # メインルーチン、 code は Array
  def eval_core(code)
    case code
    in [] then @stack.pop
    in [x, *xs]
      case x
      in Integer then @stack.push x
      in Array   then parse_array x, xs.empty?
      in Symbol  then parse_symbol x.to_s, xs.empty?
      else raise ERROR_MESSAGES[:unexpected_type]
      end
      eval_core xs
    end
  end

  def parse_array(x, em) = @stack.push(em && func?(x) ? eval_core(x) : x)

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
    elsif @env[s].is_a?(Array)
      # name が Array を参照しているときも、Array の最後だったら実行する、でなければ実行せずに積む
      if em
        @stack.push eval_core(Const.deep_copy(@env[s]))
      else
        @stack.push           Const.deep_copy(@env[s])
      end
    else
      @stack.push @env[s] # ふつうの name
    end
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
  p emehcs2.run('[3 4 :+]')
end
