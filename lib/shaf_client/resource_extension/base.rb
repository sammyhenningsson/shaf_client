class ShafClient
  module ResourceExtension
    class Base
      def self.inherited(mod)
        ResourceExtension.register(mod)
      end

      def self.call(*args)
        raise NotImplementedError, "Class '#{self}' must respond to `call`"
      end
    end
  end
end
