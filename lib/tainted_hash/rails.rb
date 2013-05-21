require File.expand_path("../../tainted_hash", __FILE__)

TaintedHash.send :include, TaintedHash::RailsMethods

module TaintedHash::Controller
  def wrap_params_with_tainted_hash
    @_params = TaintedHash.new(@_params)
  end
end

if defined?(ActionController::Base)
  ActionController::Base.send :include, TaintedHash::Controller
end

if defined?(HashWithIndifferentAccess)
  TaintedHash.default_hash_class = HashWithIndifferentAccess
end
