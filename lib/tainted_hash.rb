require 'set'

class TaintedHash < Hash
  VERSION = "0.2.0"

  class UnexposedError < StandardError
    # Builds an exception when a TaintedHash has some unexposed keys.  Useful
    # for testing and production notification of weird parameters.
    def initialize(action, extras)
      @action = action
      @extras = extras
      super("Extra params for #{@action} in tainted hash: #{@extras.inspect}")
    end
  end

  class << self
    attr_accessor :default_hash_class
  end

  self.default_hash_class = Hash

  def self.on_no_expose(&block)
    @on_no_expose = block
  end

  def self.trigger_no_expose(hash)
    @on_no_expose.call hash if @on_no_expose && (!block_given? || yield)
  end

  # Public: Gets the original hash that is being wrapped.
  #
  # Returns a Hash.
  def original_hash
    untaint_original_hash(@original_hash)
  end

  # A Tainted Hash only exposes expected keys.  You can either expose them
  # manually, or through common Hash methods like #values_at or #slice.  Once
  # created, the internal Hash is frozen from future updates.
  #
  # hash      - Optional Hash used internally.
  # new_class - Optional class used to create basic Hashes.  Default: Hash.
  #
  def initialize(hash = nil, new_class = nil)
    @new_class = new_class || (hash && hash.class) || self.class.default_hash_class
    @original_hash = (hash && hash.dup) || @new_class.new
    @exposed_nothing = true

    @original_hash.keys.each do |key|
      key_s = key.to_s
      next if key_s == key
      @original_hash[key_s] = @original_hash.delete(key)
    end
  end

  # Public: Exposes one or more keys for the hash.
  #
  # *keys - One or more String keys.
  #
  # Returns this TaintedHash.
  def expose(*keys)
    @exposed_nothing = false
    keys.each do |key|
      key_s = key.to_s
      self[key_s] = @original_hash[key_s] if @original_hash.key?(key_s)
    end
    self
  end

  # Public: Exposes every key of the hash.
  #
  # Returns this TaintedHash.
  def expose_all
    @exposed_nothing = false
    @original_hash.each do |key, value|
      self[key] = value
    end
    self
  end

  # Public: Gets the unexposed keys from the original Hash.
  #
  # Returns an Array of String keys.
  def extra_keys
    @original_hash.keys - self.keys
  end

  # Public: Fetches the value in the hash at key, or a sensible default.
  #
  # key     - A String key to retrieve.
  # default - A sensible default.
  #
  # Returns the value of the key, or the default.
  def fetch(key, default = nil)
    key_s = key.to_s
    return default if !@original_hash.key?(key_s)
    get_original_hash_value(key_s)
  end

  # Public: Gets the value for the key but does not expose the key for the Hash.
  #
  # key - A String key to retrieve.
  #
  # Returns the value of at the key in Hash.
  def [](key)
    key_s = key.to_s
    return if !@original_hash.key?(key_s)
    get_original_hash_value(key_s)
  end

  # Public: Attempts to set the key of a frozen hash.
  #
  # key   - String key to set.
  # value - Value of the key.
  #
  # Returns nothing
  def []=(key, value)
    key_s = key.to_s
    super(key_s, set_original_hash_value(key_s, value))
  end

  # Public: Deletes the value from both the internal and current Hash.
  #
  # key - A String key to delete.
  #
  # Returns the value from the key.
  def delete(key)
    key_s = key.to_s
    super(key_s)
    @original_hash.delete key_s
  end

  # Public: Checks whether the given key has been exposed or not.
  #
  # key - A String key.
  #
  # Returns true if exposed, or false.
  def include?(key)
    super(key.to_s)
  end

  alias key? include?

  # Public: Returns the values for the given keys, and exposes the keys.
  #
  # *keys - One or more String keys.
  #
  # Returns an Array of the values (or nil if there is no value) for the keys.
  def values_at(*keys)
    keys.map { |k| get_original_hash_value(k.to_s) }
  end

  # Public: Produces a copy of the current Hash with the same set of exposed
  # keys as the original Hash.
  #
  # Returns a dup of this TaintedHash.
  def dup()
    dup = super()
    dup.set_original_hash(@original_hash.dup)
  end

  # Public: Merges the given hash with the internal and a dup of the current
  # Hash.
  #
  # hash - A Hash with String keys.
  #
  # Returns a dup of this TaintedHash.
  def merge(hash)
    dup.update(hash)
  end

  # Public: Updates the internal and current Hash with the given Hash.
  #
  # hash - A Hash with String keys.
  #
  # Returns this TaintedHash.
  def update(hash)
    hash.each do |key, value|
      self[key.to_s] = value
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
    self.class.trigger_no_expose(self) { @exposed_nothing && size.zero? }
    block = block_given? ? Proc.new : nil
    super(&block)
  end

  # Public: Builds a normal Hash of the exposed values from this hash.
  #
  # Returns a Hash.
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

  def with_indifferent_access
    self
  end

  def inspect
    %(#<#{self.class}:#{object_id} @hash=#{@original_hash.inspect} @exposed=#{keys.inspect}>)
  end

protected
  def set_original_hash(hash)
    @original_hash = hash
    self
  end

  def get_original_hash
    return @original_hash
  end

private
  def get_original_hash_value(key_s)
    set_original_hash_value(key_s, @original_hash[key_s])
  end

  def set_original_hash_value(key_s, value)
    if value.is_a?(Hash) && !value.is_a?(TaintedHash)
      value = self.class.new(value, @new_class)
    end

    @original_hash[key_s] = value
  end

  # Private: Returns a regular Hash, transforming all embedded TaintedHash
  # objects into regular Hash objects with all keys exposed.
  #
  # original_hash - The @original_hash you want to untaint
  #
  #
  # Returns a Hash
  def untaint_original_hash(original_hash)
    hash = @new_class.new
    original_hash.each do |key, value|
      hash[key] = case value
        when TaintedHash then untaint_original_hash(value.get_original_hash)
        else value
        end
    end
    hash
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
      str_keys = @original_hash.keys & keys.map { |k| k.to_s }
      hash = self.class.new
      str_keys.each do |key|
        hash[key] = @original_hash[key]
      end
      hash
    end

    def slice!(*keys)
      raise NotImplementedError
    end

    def stringify_keys
      self
    end

    def to_query
      @original_hash.to_query
    end
  end
end
