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
    @primitive_run = 0
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

  def my_if
    @stack.pop if common1 == 'false'
    ret = common1
    # puts "if: #{ret}"
    @stack.push ret
  end

  def eq        = (y1, y2 = common2; @stack.push(y2 == y1 ? 'true' : 'false'))
  def plus      = (y1, y2 = common2; @stack.push y1 + y2)

  def minus     = (y1, y2 = common2; @stack.push y2 - y1)
  def mul       = (y1, y2 = common2; @stack.push y1 * y2)
  def div       = (y1, y2 = common2; @stack.push y2 / y1)
  def mod       = (y1, y2 = common2; @stack.push y2 % y1)
  def lt        = (y1, y2 = common2; @stack.push(y2 < y1 ? 'true' : 'false'))
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

  def run(str)
    @stack = []
    eval_core(read(str)) { |ret| @out = ret }
    show @out
  end

  private

  # メインルーチン、 code は Array、末尾再帰を実現
  def eval_core(code, &bk)
    case code
    in [] then yield @stack.pop
    in [x, *xs]
      case x
      in Integer then @stack.push x; eval_core(xs, &bk)
      in Array   then parse_array x, xs, &bk
      in Symbol  then parse_symbol x.to_s, xs, &bk
      else raise ERROR_MESSAGES[:unexpected_type]
      end
    end
  end

  def parse_array(x, xs, em = xs.empty?, &bk)
    if em && func?(x)
      eval_core(x) do |ret|
        @stack.push ret
        eval_core(xs, &bk)
      end
    else
      @stack.push x
      eval_core(xs, &bk)
    end
  end

  def parse_symbol_sub(s, em)
    @primitive_run += 1
    if    EMEHCS2_FUNC_TABLE.key? s
      em ? send(EMEHCS2_FUNC_TABLE[s]) : @stack.push(s)             # プリミティブ関数実行1
    elsif EMEHCS2_FUNC_TABLE.key? @env[s]
      em ? send(EMEHCS2_FUNC_TABLE[@env[s]]) : @stack.push(@env[s]) # プリミティブ関数実行2
    end
    @primitive_run -= 1
  end

  def parse_symbol(s, xs, em = xs.empty?, name = s[1..], &bk)
    # if EMEHCS2_FUNC_TABLE.key?(s) || EMEHCS2_FUNC_TABLE.key?(@env[s])
    #   parse_symbol_sub s, em
    #   eval_core xs
    if em && (s == '+' || @env[s] == '+')
      @primitive_run += 1
      eval_core([pop_raise]) do |y1|
        eval_core([pop_raise]) do |y2|
          @stack.push y1 + y2
          @primitive_run -= 1
          eval_core(xs, &bk)
        end
      end
    elsif em && (s == '==' || @env[s] == '==')
      @primitive_run += 1
      eval_core([pop_raise]) do |y1|
        eval_core([pop_raise]) do |y2|
          @stack.push y2 == y1 ? 'true' : 'false'
          @primitive_run -= 1
          eval_core(xs, &bk)
        end
      end
    elsif em && (s == 'if' || @env[s] == 'if')
      @primitive_run += 1
      eval_core([pop_raise]) do |y1|
        @stack.pop if y1 == 'false'
        eval_core([pop_raise]) do |y2|
          @stack.push y2
          @primitive_run -= 1
          eval_core(xs, &bk)
        end
      end
    elsif s[0] == 'F' # 関数束縛
      ret = pop_raise
      ret.map! { |x| x == name.to_sym ? @env[name] : x } if @env[name].is_a?(Integer)
      @env[name] = ret
      eval_core(xs, &bk)
    elsif @env[s].is_a?(Array)
      # name が Array を参照しているときも、Array の最後だったら実行する、でなければ実行せずに積む
      if em || !@primitive_run.zero?
        # input = Const.deep_copy @env[s]
        # input = input.to_sym if input.is_a?(String)
        eval_core(Const.deep_copy(@env[s])) do |ret2|
          @env[s] = ret2
          @stack.push ret2
          eval_core(xs, &bk)
        end
      else
        @stack.push Const.deep_copy @env[s]
        eval_core(xs, &bk)
      end
    else
      @stack.push @env[s] # s が変数名
      eval_core(xs, &bk)
    end
  end
end

# Trcall クラス
class Trcall < Emehcs2
  def initialize(name)
    super()
    alias hoo eval
    @first = true
    hoo <<"DEF"
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

# メイン関数としたもの
if __FILE__ == $PROGRAM_NAME
  tr = Trcall.new(:eval_core)
  # p emehcs2.read('[[3 4 5] 1 2 :+]')
  # p emehcs2.show([3, 4, :foo])
  # p emehcs2.run('[3 4 :+]')
  str = '[[:Fx [[:x 1 :+] :g] :x [:x 200 :==] :if] :Fg 0 :g]' # スタックオーバーフローを回避
  tr.eval_core(tr.read(str)) { |ret| puts tr.show ret }
end
