# Tainted Hash

A TaintedHash is a wrapper around a normal Hash that only exposes the keys that
have been approved.  This is useful in cases where a Hash is built from user
input from an external service (such as Rails or Sinatra).  By forcing the 
developer to approve keys, no unexpected keys are passed to data stores.
Because of this specific use case, it is assumed all keys are strings.

By default, no keys have been approved.

```ruby
hash = {'a' => 1, 'b' => 2', 'c' => 3}
tainted = TaintedHash.new hash
```

You can access keys manually to get the value and approve them:

```ruby
tainted.include?(:a) # false
tainted['a'] # Returns 2
tainted[:a]  # Symbols are OK too.
tainted.include?(:a) # true
tainted.keys # ['a']

tainted.fetch(:b) # Returns 2
tainted.include?(:b) # true
tainted.keys # ['a', 'b']

tainted.values_at(:b, :c) # Returns [2, 3]
tainted.include?(:c) # true
tainted.keys # ['a', 'b', 'c']
```

You can also explicitly expose keys:

```ruby
tainted.expose :a, :b
```

If using Rails 2.3, require `tainted_hash/rails` to setup the necessary hooks.
It amounts to little more than this:

```ruby
def wrap_params_with_tainted_hash
  @_params = TaintedHash.new(@_params.to_hash)
end
```

Set this up as a `before_filter` early in the stack.  However, it should run
after filters like `#filter_parameter_logging` that needs to filter _any_
key.

## Note on Patches/Pull Requests
1. Fork the project on GitHub.
2. Make your feature addition or bug fix.
3. Add tests for it. This is important so I don't break it in a future version
   unintentionally.
4. Commit, do not mess with rakefile, version, or history. (if you want to have
   your own version, that is fine but bump version in a commit by itself I can
   ignore when I pull)
5. Send me a pull request. Bonus points for topic branches.

