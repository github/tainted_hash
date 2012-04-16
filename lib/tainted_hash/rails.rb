require File.expand_path("../../tainted_hash", __FILE__)

TaintedHash.send :include, TaintedHash::RailsMethods

module TaintedHash::Controller
  def wrap_params_with_tainted_hash
    self.params = TaintedHash.new(params.to_hash)
  end
end

if defined?(ActionController::Base)
  ActionController::Base.send :include, TaintedHash::Controller
end

