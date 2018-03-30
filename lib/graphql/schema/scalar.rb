# frozen_string_literal: true
module GraphQL
  class Schema
    class Scalar < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition

      class << self
        def coerce_input(val, ctx)
          raise NotImplementedError, "#{self.name}.coerce_input(val, ctx) must prepare GraphQL input (#{val.inspect}) for Ruby processing"
        end

        def coerce_result(val, ctx)
          raise NotImplementedError, "#{self.name}.coerce_result(val, ctx) must prepare Ruby value (#{val.inspect}) for GraphQL response"
        end

        def to_graphql
          type_defn = GraphQL::ScalarType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.default_scalar = default_scalar
          type_defn.metadata[:type_class] = self
          type_defn.coerce_result = method(:coerce_result)
          type_defn.coerce_input = method(:coerce_input)
          type_defn.metadata[:type_class] = self
          type_defn
        end

        def default_scalar(new_val = nil)
          if !new_val.nil?
            @default_scalar = new_val
          end
          @default_scalar
        end

        def evaluate_selections(object:, selections:, interpreter:)
          coerce_result(object, interpreter.query.context)
        end
      end
    end
  end
end
