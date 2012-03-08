require 'set'

class TaintedHash < Hash
  VERSION = "0.0.1"

  # Public: Gets the original hash that is being wrapped.
  #
  # Returns a Hash.
  attr_reader :hash

  # A Tainted Hash only exposes expected keys.  You can either expose them
  # manually, or through common Hash methods like #values_at or #slice.  Once
  # created, the internal Hash is frozen from future updates.
  #
  # hash - Optional Hash used internally.
  def initialize(hash = nil, exposed = nil, available = nil, new_class = nil)
    (@hash = hash || {}).keys.each do |key|
      key_s = key.to_s
      next if key_s == key
      @hash[key_s] = @hash.delete(key)
    end

    @available = available || Set.new(@hash.keys.map { |k| k.to_s })
    @exposed = exposed ? exposed.intersection(@available) : Set.new
    @new_class = new_class || Hash
    @exposed_nothing = @exposed.size.zero?
  end

  def dup(exposed = nil, available = nil)
    self.class.new(@hash.dup, exposed || @exposed, available || @available, @new_class)
  end

  # Public: Exposes one or more keys for the hash.
  #
  # *keys - One or more String keys.
  #
  # Returns nothing.
  def expose(*keys)
    @exposed_nothing = false
    keys.each do |key|
      key_s = key.to_s
      @exposed << key_s if @available.include?(key_s)
      key_s
    end
    self
  end

  def expose_all
    @exposed = @available
    @exposed_nothing = false
    self
  end
  
  # Public: Fetches the value in the hash at key, or a sensible default.
  #
  # key     - A String key to retrieve.
  # default - A sensible default.
  #
  # Returns the value of the key, or the default.
  def fetch(key, default = nil)
    expose key
    @hash.fetch key.to_s, default
  end

  # Public: Gets the value for the key, and exposes the key for the Hash.
  #
  # key - A String key to retrieve.
  #
  # Returns the value of at the key in Hash.
  def [](key)
    expose key
    case value = @hash[key.to_s]
    when TaintedHash then value
    when Hash
      @hash[key.to_s] = self.class.new(value, nil, nil, @new_class)
    else value
    end
  end

  # Public: Attempts to set the key of a frozen hash.
  #
  # key   - String key to set.
  # value - Value of the key.
  #
  # Returns nothing
  def []=(key, value)
    key_s = key.to_s
    @available << key_s
    expose key_s
    @hash[key_s] = case value
    when TaintedHash then value
    when Hash then self.class.new(value, nil, nil, @new_class)
    else value
    end
  end

  def delete(key)
    key_s = key.to_s
    @exposed.delete key_s
    @available.delete key_s
    @hash.delete key_s
  end

  # Public: Checks whether the given key has been exposed or not.
  #
  # key - A String key.
  #
  # Returns true if exposed, or false.
  def include?(key)
    @exposed.include? key.to_s
  end

  alias key? include?

  # Public: Returns the values for the given keys, and exposes the keys.
  #
  # *keys - One or more String keys.
  #
  # Returns an Array of the values (or nil if there is no value) for the keys.
  def values_at(*keys)
    str_keys = keys.map { |k| k.to_s }
    expose *str_keys
    @hash.values_at *str_keys
  end

  def merge(hash)
    dup.update(hash)
  end

  def update(hash)
    hash.each do |key, value|
      self[key] = value
    end
    self
  end

  alias merge! update

  # Public: Enumerates through the exposed keys and valuesfor the hash.
  #
  # Yields the String key, and the value.
  #
  # Returns nothing.
  def each
    raise "Nothing is expose" if @exposed_nothing && @available.size > 0
    @exposed.each do |key|
      yield key, @hash[key]
    end
  end

  def to_hash
    hash = @new_class.new
    each do |key, value| 
      hash[key] = case value
        when TaintedHash then value.to_hash
        else value
        end
    end
    hash
  end

  def to_a
    to_hash.to_a
  end

  def values
    keys.map { |k| self[k] }
  end

  # Public: Returns a list of the currently exposed keys.
  #
  # Returns an Array of String keys.
  def keys
    @exposed.to_a
  end

  def inspect
    %(#<#{self.class}:#{object_id} @hash=#{@hash.inspect} @exposed=#{@exposed.to_a.inspect}>)
  end

  module RailsMethods
    def self.included(base)
      base.send :alias_method, :stringify_keys!, :stringify_keys
    end

    # Public: Returns a portion of the Hash.
    #
    # *keys - One or more String keys.
    #
    # Returns a Hash of the requested keys and values.
    def slice(*keys)
      str_keys = @available.intersection(keys.map { |k| k.to_s })
      expose *str_keys
      hash = self.class.new
      str_keys.each do |key|
        hash[key] = self[key]
      end
      hash
    end

    def slice!(*keys)
      raise NotImplementedError
    end

    def stringify_keys
      self
    end

    def blank?
      @exposed.blank?
    end

    def present?
      @exposed.present?
    end

    def to_query
      @hash.to_query
    end
  end
end
  
