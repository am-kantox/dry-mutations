module Dry
  module Mutations
    module Errors
      class ErrorCompiler < ::Dry::Validation::ErrorCompiler # :nodoc:
        def initialize schema = nil
          super (schema && schema.error_compiler || ::Dry::Validation::Schema).messages
        end

        def visit_error(node, opts = ::Dry::Validation::EMPTY_HASH)
          rule, error = node
          node_path = Array(opts.fetch(:path, rule))
          path = (rule.is_a?(Array) && rule.size > node_path.size ? rule : node_path).compact
          text = messages[rule]

          if text
            ErrorAtom.new(
              [*node.first].join('.'),
              predicate,
              ::Dry::Validation::Message.new(node, path, text, rule: rule),
              message: text
            )
          else
            visit(error, opts.merge(path: path))
          end
        end
      end
    end
  end
end

::Dry::Validation::Schema.instance_variable_set(:@error_compiler, ::Dry::Mutations::Errors::ErrorCompiler.new)
