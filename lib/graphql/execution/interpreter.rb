# frozen_string_literal: true

module GraphQL
  module Execution
    # Implement query execution as an AST visitor.
    #
    # Goals:
    # - No rewrite required, low memory/time overhead
    # - Customizeable via redefining methods
    # - Implement lazy_resolve, support null propagation, etc.
    #
    # Non-Goals:
    # - Compatibility with analyzers
    # - Compatibility with `irep_node` 😿
    #
    # Instead, analysis will be implemented as a separate pass over the AST.
    #
    # Previously, look-ahead was done with the irep_node. Now,
    # we need some way to do that with method overrides.
    class Interpreter
      attr_reader :query
      # This method is the Executor API
      # TODO revisit Executor's reason for living.
      def execute(_ast_operation, _root_type, query)
        @query = query
        evaluate
      end

      def evaluate
        operation = query.selected_operation
        selections = operation.selections
        object_type = query.root_type_for_operation(operation.operation_type)
        application_object = query.root_value

        # TODO use classes at runtime
        object_class = object_type.metadata[:object_class]

        result = object_class.evaluate_selections(
          object: application_object,
          selections: selections,
          query: query
        )
      end
    end
  end
end
