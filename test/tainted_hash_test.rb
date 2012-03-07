require File.expand_path("../../lib/tainted_hash", __FILE__)
require 'test/unit'

class TaintedHashTest < Test::Unit::TestCase
  def setup
    @hash = {'a' => 1, 'b' => 2, 'c' => {'name' => 'bob'}}
    @tainted = TaintedHash.new @hash
  end

  def test_exposes_no_keys_by_default
    assert !@tainted.include?('a')
    assert !@tainted.include?('b')
    assert_equal [], @tainted.keys

    assert @hash.include?('a')
    assert @hash.include?('b')
    assert @hash.include?('c')
  end

  def test_approve_keys
    assert !@tainted.include?(:a)
    assert_equal [], @tainted.keys
    @tainted.approve :a
    assert @tainted.include?(:a)
    assert_equal %w(a), @tainted.keys
  end

  def test_fetching_a_value
    assert !@tainted.include?(:a)
    assert !@tainted.include?(:d)
    assert_equal 1, @tainted.fetch(:a, :default)
    assert_equal :default, @tainted.fetch(:d, :default)
    assert @tainted.include?(:a)
    assert !@tainted.include?(:d)
  end

  def test_getting_a_value
    assert !@tainted.include?(:a)
    assert_equal 1, @tainted[:a]
    assert @tainted.include?(:a)
  end

  def test_setting_a_value
    assert !@tainted.include?(:a)
    @tainted[:a] = 2
    assert @tainted.include?(:a)
    assert_equal 2, @tainted[:a]
  end

  def test_deleting_a_value
    assert_equal 1, @tainted[:a]
    assert @tainted.include?(:a)
    assert_equal 1, @tainted.delete(:a)
    assert !@tainted.include?(:a)
  end

  def test_slicing_a_hash
    assert !@tainted.include?(:a)
    assert !@tainted.include?(:b)
    assert !@tainted.include?(:c)

    output = @tainted.slice(:a, :b)
    assert_equal({'a' => 1, 'b' => 2}, output.to_hash)

    assert @tainted.include?(:a)
    assert @tainted.include?(:b)
    assert !@tainted.include?(:c)
  end

  def test_nested_hash_has_tainted_hashes
    assert_kind_of TaintedHash, @tainted[:c]
    assert_equal 'bob', @tainted[:c][:name]
  end

  def test_slicing_nested_hashes
    slice = @tainted.slice :b, :c
    assert_equal 2, slice[:b]
    assert_equal 'bob', slice[:c][:name]
    assert_equal %w(b c), slice.keys.sort
    assert_equal %w(name), slice[:c].keys
  end

  def test_slicing_and_building_hashes
    hash = {'desc' => 'abc', 'files' => {'abc.txt' => 'abc'}}
    tainted = TaintedHash.new hash

    tainted.approve :desc, :files
    assert tainted.include?(:desc)
    assert tainted.include?(:files)

    slice = tainted.slice :desc
    assert slice.include?(:desc)
    assert !slice.include?(:files)
    assert_equal %w(desc), slice.keys
    slice[:contents] = tainted[:files].approve_all
    assert slice[:contents].include?('abc.txt')
    assert_equal 'abc', slice[:contents]['abc.txt']
  end

  def test_update_hash
    assert !@tainted.include?(:a)
    assert !@tainted.include?(:d)
    @tainted.update :a => 2, :d => 1
    assert @tainted.include?(:a)
    assert @tainted.include?(:d)
    assert_equal 2, @tainted[:a]
    assert_equal 1, @tainted[:d]
  end

  def test_does_not_approve_missing_keys
    assert !@tainted.include?(:a)
    assert !@tainted.include?(:d)
    @tainted.approve :a, :d
    assert @tainted.include?(:a)
    assert !@tainted.include?(:d)
  end

  def test_values_at_approves_keys
    assert !@tainted.include?(:a)
    assert !@tainted.include?(:b)
    assert !@tainted.include?(:d)
    assert_equal [1,2, nil], @tainted.values_at(:a, :b, :d)
    assert @tainted.include?(:a)
    assert @tainted.include?(:b)
    assert !@tainted.include?(:d)
  end

  def test_requires_something_to_be_approved
    assert_raises RuntimeError do
      @tainted.to_hash
    end

    @tainted.approve :missing
    assert_equal({}, @tainted.to_hash)
    @tainted.approve :a
    assert_equal({'a' => 1}, @tainted.to_hash)
  end
end

