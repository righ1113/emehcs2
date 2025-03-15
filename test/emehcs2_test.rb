# frozen_string_literal: true

# ・実行方法
# $ cd emehcs2
# $ ruby test/emehcs2_test.rb

require 'minitest/autorun'
require './emehcs2'

class Emehcs2Test < Minitest::Test
  def test_case1
    code1 = '[[3 4 5] 1 2 :+]'
    code2 = [3, 4, :foo]
    code3 = '[3 4 :+]'
    code4 = '[3 [3 4 :+] :+]'
    code5 = '[[:"=x" [[:x 1 :+] :g] :x [:x 100 :==] :if] :">g" 0 :g]'

    emehcs2 = Emehcs2.new
    assert_equal [[3, 4, 5], 1, 2, :+], (emehcs2.read code1)
    assert_equal '[3 4 :foo]',          (emehcs2.show code2)
    assert_equal '7',                   (emehcs2.run code3)
    assert_equal '10',                  (emehcs2.run code4)
    assert_equal '100',                 (emehcs2.run code5)

    # _code16 = emehcs.parse2 <<~TEXT
    #   ; これはコメントです。
    #   (
    #     (=out =x (
    #       ((x 3x+1) (out x cons) collatz)
    #       ((x x/2)  (out x cons) collatz) (x even?)) (out 1 cons) (x 2 <)) >collatz
    #     5 [] collatz)
    # TEXT
  end
end
