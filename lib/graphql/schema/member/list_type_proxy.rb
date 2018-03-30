# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      # Wraps a {Schema::Member} as a list type.
      # @see {Schema::Member#to_list_type}
      # @api private
      class ListTypeProxy
        include GraphQL::Schema::Member::CachedGraphQLDefinition

        def initialize(member)
          @member = member
        end

        def to_graphql
          @member.graphql_definition.to_list_type
        end

        def to_non_null_type
          NonNullTypeProxy.new(self)
        end

        def evaluate_selections(object:, selections:, interpreter:)
          @member.evaluate_selections(object: object, selections: selections, interpreter: interpreter)
        end
      end
    end
  end
end
