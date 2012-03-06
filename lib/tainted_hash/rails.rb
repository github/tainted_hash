require File.expand_path("../../tainted_hash", __FILE__)

if Object.const_defined?(:Rails)
  case Rails.version
  when /^2\.3\./
    class ActionController::Request
      alias rails_parameters parameters
      def parameters
        @parameters ||= TaintedHash.new(rails_parameters, nil, nil, HashWithIndifferentAccess)
      end
    end
  end
else
  raise "Not a supported Rails project"
end
