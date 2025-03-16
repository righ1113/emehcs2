# frozen_string_literal: true

# ・以下は1回だけおこなう
# rbenv で Ruby 3.3.5(じゃなくてもいい) を入れる
# $ gem install bundler
# $ cd emehcs2
# $ bundle install --path=vendor/bundle

# ・実行方法
# $ cd emehcs2
# $ bundle exec ruby emehcs2.rb

# require 'time'
require './lib/const'
require './lib/parse2_core'
# require './lib/repl'

# EmehcsBase2 クラス
class EmehcsBase2
  include Const
  include Parse2Core
  def initialize
    @env           = {}
    @stack         = []
    @primitive_run = 0
  end

  private

  def parse_symbol(s, xs, em = xs.empty?, name = s[1..], &bk)
    if    em && EMEHCS2_FUNC_TABLE1.key?(s)
      @primitive_run += 1
      eval_core [pop_raise] do |y1|
        send(EMEHCS2_FUNC_TABLE1[s], y1) # 各プリミティブ関数実行_引数1
        @primitive_run -= 1
        eval_core xs, &bk
      end
    elsif em && EMEHCS2_FUNC_TABLE2.key?(s)
      @primitive_run += 1
      eval_core [pop_raise] do |y1|
        eval_core [pop_raise] do |y2|
          send(EMEHCS2_FUNC_TABLE2[s], y1, y2) # 各プリミティブ関数実行_引数2
          @primitive_run -= 1
          eval_core xs, &bk
        end
      end
    elsif em && s == 'up_p'
      @primitive_run += 1
      eval_core [pop_raise] do |y1|
        eval_core [pop_raise] do |y2|
          eval_core [pop_raise] do |y3|
            y3[y2] += y1; @stack.push y3
            @primitive_run -= 1
            eval_core xs, &bk
          end
        end
      end
    elsif em && s == '?'
      @primitive_run += 1
      eval_core [pop_raise] do |y1|
        @stack.pop if y1 == 'false'
        eval_core [pop_raise] do |y2|
          @stack.push y2
          @primitive_run -= 1
          eval_core xs, &bk
        end
      end
    elsif em && s == '&&'
      @primitive_run += 1
      eval_core [pop_raise] do |y1|
        if y1 == 'false'
          pop_raise
          @stack.push 'false'
          @primitive_run -= 1
          eval_core xs, &bk
        else
          eval_core [pop_raise] do |y2|
            @stack.push y2
            @primitive_run -= 1
            eval_core xs, &bk
          end
        end
      end
    elsif s[0] == '>' # 関数束縛
      ret = pop_raise
      @env[name] = ret
      @stack.push ret
      eval_core xs, &bk
    elsif s[0] == '=' # 変数束縛
      ret1 = pop_raise
      if func? ret1
        eval_core ret1 do |ret2|
          @env[name] = ret2
          eval_core xs, &bk
        end
      else
        @env[name] = ret1
        eval_core xs, &bk
      end
    elsif func?(@env[s])
      # name が Array を参照しているときも、Array の最後だったら実行する、でなければ実行せずに積む
      if em || !@primitive_run.zero?
        eval_core Const.deep_copy @env[s] do |ret2|
          @stack.push ret2
          eval_core xs, &bk
        end
      else
        @stack.push Const.deep_copy @env[s]
        eval_core xs, &bk
      end
    elsif !@env[s].nil?
      @stack.push @env[s] # s が変数名
      eval_core xs, &bk
    else
      @stack.push s.to_sym
      eval_core xs, &bk # 純粋シンボル
    end
  end
end

# Emehcs2 クラス 相互に呼び合っているから、継承しかないじゃん
class Emehcs2 < EmehcsBase2
  # Expr = Int | Sym | [Expr]
  def read(str)  = eval str.gsub(' ', ', ')
  def read2(str) = parse2_core str
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
      in Integer then @stack.push  x; eval_core xs, &bk
      in Array   then parse_array  x,           xs, &bk
      in Symbol  then parse_symbol x.to_s,      xs, &bk # 親クラスへ
      else            raise "予期しない型 #{x}"
      end
    end
  end

  private

  def parse_array(x, xs, em = xs.empty?, &bk)
    if em && func?(x)
      eval_core x do |ret|
        @stack.push ret
        eval_core xs, &bk
      end
    else
      @stack.push x
      eval_core xs, &bk
    end
  end
end

# Trcall クラス
class Trcall < Emehcs2
  def initialize(name)
    super()
    @first = true
    eval <<"DEF"
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
  tr  = Trcall.new(:eval_core)
  str = File.read('sample/bf.eme')
  tr.eval_core(tr.read2(str)) { |ret| puts tr.show ret }
  str = File.read('sample/zdk.eme')
  tr.eval_core(tr.read2(str)) { |ret| puts tr.show ret }
end
