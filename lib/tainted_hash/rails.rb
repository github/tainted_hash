require File.expand_path("../../tainted_hash", __FILE__)

module TaintedHash::Controller
  def wrap_params_with_tainted_hash
    @_params = TaintedHash.new(@_params.to_hash)
  end
end

if defined?(ActionController::Base)
  ActionController::Base.send :include, TaintedHash::Controller
end

