require 'set'

class TaintedHash
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
  def initialize(hash = nil)
    @hash = (hash || {}).freeze
    @available = Set.new @hash.keys.map { |k| k.to_s }
    @approved = Set.new
  end

  # Public: Approves one or more keys for the hash.
  #
  # *keys - One or more String keys.
  #
  # Returns nothing.
  def approve(*keys)
    keys.map! do |key|
      key_s = key.to_s
      @approved << key_s if @available.include?(key_s)
      key_s
    end
  end

  # Public: Gets the value for the key, and approves the key for the Hash.
  #
  # key - A String key to retrieve.
  #
  # Returns the value of at the key in Hash.
  def [](key)
    approve key
    @hash[key.to_s]
  end

  # Public: Attempts to set the key of a frozen hash.
  #
  # key   - String key to set.
  # value - Value of the key.
  #
  # Returns nothing
  def []=(key, value)
    raise ArgumentError, "Cannot modify tainted hash"
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
    keys = approve *keys
    @hash.values_at *keys
  end

  # Public: Enumerates through the approved keys and valuesfor the hash.
  #
  # Yields the String key, and the value.
  #
  # Returns nothing.
  def each
    @approved.each do |key|
      yield key, @hash[key]
    end
  end

  # Public: Returns a list of the currently approved keys.
  #
  # Returns an Array of String keys.
  def keys
    @approved.to_a
  end
end
  
