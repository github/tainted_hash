require 'set'

class TaintedHash < Hash
  VERSION = "0.0.1"

  # Public: Gets the original hash that is being wrapped.
  #
  # Returns a Hash.
  attr_reader :hash

  # A Tainted Hash only exposes expected keys.  You can either approve them
  # manually, or through common Hash methods like #values_at or #slice.  Once
  # created, the internal Hash is frozen from future updates.
  #
  # hash - Optional Hash used internally.
  def initialize(hash = nil, approved = nil, available = nil, new_class = nil)
    @hash = hash || {}
    @available = available || Set.new(@hash.keys.map { |k| k.to_s })
    @approved = approved ? approved.intersection(@available) : Set.new
    @new_class = new_class || Hash
  end

  def dup
    self.class.new(@hash.dup, @approved, @available, @new_class)
  end

  # Public: Approves one or more keys for the hash.
  #
  # *keys - One or more String keys.
  #
  # Returns nothing.
  def approve(*keys)
    keys.each do |key|
      key_s = key.to_s
      @approved << key_s if @available.include?(key_s)
      key_s
    end
    self
  end

  def approve_all
    @approved = @available
    self
  end
  
  # Public: Fetches the value in the hash at key, or a sensible default.
  #
  # key     - A String key to retrieve.
  # default - A sensible default.
  #
  # Returns the value of the key, or the default.
  def fetch(key, default = nil)
    approve key
    @hash.fetch key.to_s, default
  end

  # Public: Gets the value for the key, and approves the key for the Hash.
  #
  # key - A String key to retrieve.
  #
  # Returns the value of at the key in Hash.
  def [](key)
    approve key
    case value = @hash[key.to_s]
    when TaintedHash then value
    when Hash then self.class.new(value, nil, nil, @new_class)
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
    approve key_s
    @hash[key_s] = value
  end

  def delete(key)
    key_s = key.to_s
    @approved.delete key_s
    @available.delete key_s
    @hash.delete key_s
  end

  # Public: Checks whether the given key has been approved or not.
  #
  # key - A String key.
  #
  # Returns true if approved, or false.
  def include?(key)
    @approved.include? key.to_s
  end

  alias key? include?

  # Public: Returns the values for the given keys, and approves the keys.
  #
  # *keys - One or more String keys.
  #
  # Returns an Array of the values (or nil if there is no value) for the keys.
  def values_at(*keys)
    str_keys = keys.map { |k| k.to_s }
    approve *str_keys
    @hash.values_at *str_keys
  end

  # Public: Returns a portion of the Hash.
  #
  # *keys - One or more String keys.
  #
  # Returns a Hash of the requested keys and values.
  def slice(*keys)
    str_keys = keys.map { |k| k.to_s }
    approve *str_keys
    self.class.new(to_hash, @approved, Set.new(str_keys), @new_class)
  end

  alias slice! slice

  def stringify_keys
    self
  end

  alias stringify_keys! stringify_keys

  def update(hash)
    hash.each do |key, value|
      self[key] = value
    end
    self
  end

  alias merge update
  alias merge! update

  # Public: Enumerates through the approved keys and valuesfor the hash.
  #
  # Yields the String key, and the value.
  #
  # Returns nothing.
  def each
    raise "Nothing is approved" if @approved.size.zero? && @available.size > 0
    @approved.each do |key|
      yield key, @hash[key]
    end
  end

  def to_hash
    hash = @new_class.new
    each { |key, value| hash[key] = value }
    hash
  end

  def to_query
    @hash.to_query
  end

  # Public: Returns a list of the currently approved keys.
  #
  # Returns an Array of String keys.
  def keys
    @approved.to_a
  end

  def inspect
    %(#<#{self.class}:#{object_id} @hash=#{@hash.inspect} @approved=#{@approved.to_a.inspect}>)
  end
end
  
