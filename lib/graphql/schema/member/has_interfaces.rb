# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      # Shared code for Object and Interface
      module HasInterfaces
        def implements(*new_interfaces)
          new_interfaces.each do |int|
            if int.is_a?(Module)
              # Include the methods here,
              # `.fields` will use the inheritance chain
              # to find inherited fields
              include(int)
            end
          end
          own_interfaces.concat(new_interfaces)
        end

        def interfaces
          own_interfaces + (superclass.respond_to?(:interfaces) ? superclass.interfaces : [])
        end

        def own_interfaces
          @own_interfaces ||= []
        end
      end
    end
  end
end
