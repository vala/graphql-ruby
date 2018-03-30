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
    #
    # The interpreter is going to be the centralized host
    # of runtime caches like fragment spreads and
    # prepared argument values.
    #
    # Somehow, those cached values should be shared
    # between passes over the tree.
    #
    # TODO: could it be made into a straight-up AST visitor?
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

        result = object_type.evaluate_selections(
          object: application_object,
          selections: selections,
          interpreter: self,
        )
      end

      # This is a new codepath for Query::ArgumentsCache
      # and
      # TODO: HAHAH this is very not good
      # - Apply scalar coerce functions
      # - Consider `variables`
      # - Cache the results and reuse them?
      def arguments_for(ast_node, field_instance)
        ruby_kwargs = {}
        ast_node.arguments.each do |ast_arg|
          ruby_kwargs[Schema::Member::BuildType.underscore(ast_arg.name).to_sym] = ast_arg.value
        end
        ruby_kwargs
      end
    end
  end
end
