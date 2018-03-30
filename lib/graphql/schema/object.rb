# frozen_string_literal: true

module GraphQL
  class Schema
    class Object < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend GraphQL::Schema::Member::HasFields

      # @return [Object] the application object this type is wrapping
      attr_reader :object

      # @return [GraphQL::Query::Context] the context instance for this query
      attr_reader :context

      def initialize(object, context)
        @object = object
        @context = context
      end

      class << self
        def implements(*new_interfaces)
          new_interfaces.each do |int|
            if int.is_a?(Class) && int < GraphQL::Schema::Interface
              # Add the graphql field defns
              int.fields.each do |name, field|
                own_fields[name] = field
              end
              # And call the implemented hook
              int.implemented(self)
            else
              int.all_fields.each do |f|
                field(f.name, field: f)
              end
            end
          end
          own_interfaces.concat(new_interfaces)
        end

        def interfaces
          own_interfaces + (superclass <= GraphQL::Schema::Object ? superclass.interfaces : [])
        end

        def own_interfaces
          @own_interfaces ||= []
        end

        # @return [GraphQL::ObjectType]
        def to_graphql
          obj_type = GraphQL::ObjectType.new
          obj_type.name = graphql_name
          obj_type.description = description
          obj_type.interfaces = interfaces
          obj_type.introspection = introspection
          obj_type.mutation = mutation

          fields.each do |field_name, field_inst|
            field_defn = field_inst.to_graphql
            obj_type.fields[field_defn.name] = field_defn
          end

          obj_type.metadata[:type_class] = self

          obj_type
        end

        def evaluate_selections(object:, selections:, interpreter:)
          result = {}
          # Apply the type definition as a wrapper around the application object
          type_proxy = self.new(object, interpreter.query.context)
          selections.each do |ast_field|
            field = fields.fetch(Member::BuildType.underscore(ast_field.name))
            args = interpreter.arguments_for(ast_field, field)
            field_result = field.resolve(type_proxy, args)
            field_result_name = ast_field.alias || ast_field.name
            # TODO shouldn't require metadata
            next_type = field.type
            # TODO This method name (`evaluate_selections`) doesn't make sense for scalars
            finished_result = next_type.evaluate_selections(
                object: field_result,
                selections: ast_field.selections,
                interpreter: interpreter,
            )
            result[field_result_name] = finished_result
          end
          result
        end
      end
    end
  end
end
