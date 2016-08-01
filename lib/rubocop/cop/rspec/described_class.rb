# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # If the first argument of describe is a class, the class is exposed to
      # each example via described_class - this should be used instead of
      # repeating the class.
      #
      # @example
      #   # bad
      #   describe MyClass do
      #     subject { MyClass.do_something }
      #   end
      #
      #   # good
      #   describe MyClass do
      #     subject { described_class.do_something }
      #   end
      class DescribedClass < Cop
        include RuboCop::RSpec::TopLevelDescribe

        MESSAGE = 'Use `described_class` instead of `%s`'.freeze

        def on_block(node)
          method, _args, body = *node
          return unless top_level_describe?(method)

          _receiver, _method_name, object = *method
          return unless object && object.type.equal?(:const)

          inspect_children(body, object)
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.loc.expression, 'described_class')
          end
        end

        private

        def inspect_children(node, object)
          return unless node.instance_of?(Node)
          return if scope_change?(node) || node.type.equal?(:const)

          node.children.each do |child|
            if child.eql?(object)
              name = object.loc.expression.source
              add_offense(child, :expression, format(MESSAGE, name))
            end
            inspect_children(child, object)
          end
        end

        def scope_change?(node)
          [:def, :class, :module].include?(node.type)
        end
      end
    end
  end
end