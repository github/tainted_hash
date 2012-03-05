require File.expand_path("../../lib/tainted_hash", __FILE__)
require 'test/unit'

class TaintedHashTest < Test::Unit::TestCase
  def setup
    @hash = {:a => 1, :b => 2, :c => 3}
    @tainted = TaintedHash.new @hash
  end

  def test_exposes_no_keys_by_default
    assert !@tainted.include?(:a)
    assert !@tainted.include?(:b)
    assert_equal [], @tainted.keys

    assert @hash.include?(:a)
    assert @hash.include?(:b)
    assert @hash.include?(:c)
  end

  def test_approve_keys
    assert !@tainted.include?(:a)
    assert_equal [], @tainted.keys
    @tainted.approve :a
    assert @tainted.include?(:a)
    assert_equal [:a], @tainted.keys
  end

  def test_values_at_approves_keys
    assert !@tainted.include?(:a)
    assert !@tainted.include?(:b)

    assert_equal [1,2], @tainted.values_at(:a, :b)
    assert @tainted.include?(:a)
    assert @tainted.include?(:b)
  end
end

