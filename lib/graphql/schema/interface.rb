# frozen_string_literal: true
module GraphQL
  class Schema
    module Interface
      include GraphQL::Schema::Member::GraphQLTypeNames
      module DefinitionMethods
        include GraphQL::Schema::Member::CachedGraphQLDefinition
        include GraphQL::Relay::TypeExtensions
        include GraphQL::Schema::Member::BaseDSLMethods
        include GraphQL::Schema::Member::HasFields

        def definition_methods(&block)
          DefinitionMethods.module_eval(&block)
        end

        # Here's the tricky part. Make sure behavior keeps making its way down the inheritance chain.
        def extended(child_interface)
          if !child_interface.is_a?(Class)
            # In this case, it's been included into another interface.
            # This is how interface inheritance is implemented
            if !defined?(child_interface::DefinitionMethods)
              mod = Module.new
              child_interface.const_set(:DefinitionMethods, mod)
              mod
            end
            child_interface.extend(child_interface::DefinitionMethods)
            # We need this before we can call `own_interfaces`
            child_interface.extend(Schema::Interface::DefinitionMethods)
            # This provides type aliases ID, Boolean, Int
            child_interface.include(GraphQL::Schema::Member::GraphQLTypeNames)
            child_interface.own_interfaces << self
            child_interface.own_interfaces.each do |interface_defn|
              child_interface.extend(interface_defn::DefinitionMethods)
            end
          end

          super
        end

        def included(child_class)
          if child_class < GraphQL::Schema::Object
            # This is being included into an object type, make sure it's using `implements(...)`
            backtrace_line = caller(0, 10).find { |line| line.include?("schema/object.rb") && line.include?("in `implements'")}
            if !backtrace_line
              raise "Attach interfaces using `implements(#{self})`, not `include(#{self})`"
            end
          end
          child_class.extend(self::DefinitionMethods)
          super
        end

        def orphan_types(*types)
          if types.any?
            @orphan_types = types
          else
            all_orphan_types = @orphan_types || []
            all_orphan_types += super if defined?(super)
            all_orphan_types.uniq
          end
        end

        def to_graphql
          type_defn = GraphQL::InterfaceType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.orphan_types = orphan_types
          fields.each do |field_name, field_inst|
            field_defn = field_inst.graphql_definition
            type_defn.fields[field_defn.name] = field_defn
          end
          type_defn.metadata[:type_class] = self
          if respond_to?(:resolve_type)
            type_defn.resolve_type = method(:resolve_type)
          end
          type_defn
        end

        protected

        def own_interfaces
          @own_interfaces ||= []
        end
      end

      extend DefinitionMethods
      # Extend this _after_ `DefinitionMethods` is defined, so it will be used
      extend GraphQL::Schema::Member::AcceptsDefinition
    end
  end
end
