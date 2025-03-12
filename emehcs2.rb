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

  def parse_symbol(s, xs, em = xs.empty?, name = s[1..], &bk)
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

  # メインルーチン、 code は Array、末尾再帰を実現
  def eval_core(code, &bk)
    case code
    in [] then yield @stack.pop # yield はこの一ヶ所のみ
    in [x, *xs]
      case x
      in Integer then @stack.push x; eval_core(xs, &bk)
      in Array   then parse_array  x,      xs, &bk
      in Symbol  then parse_symbol x.to_s, xs, &bk # 親クラスへ
      else raise ERROR_MESSAGES[:unexpected_type]
      end
    end
  end

  private

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
