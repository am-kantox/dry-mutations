module Dry
  module Mutations
    module DSL
      module Types # :nodoc:
        class Nested # :nodoc:
          def self.init current
            @current = current
            instance_eval(&Proc.new) if block_given?
            schema
          end

          def self.! current, &cb
            Class.new(Nested).init current, &cb
          end
        end
        # private_constant :Nested

        ########################################################################
        ### enumerables
        ########################################################################

        # FIXME: errors in double+ nested hashes are not nested! dry-rb glitch?
        def hash name, **_params, &cb
          current = @current # closure scope

          schema { __send__(current, name).schema(Nested.!(current, &cb)) }

          define_method(name) { Utils::Hash(@inputs[name]) } unless Nested === self
        end

        # FIXME: array of anonymous objects
        def array name, **_params, &cb
          current = @current # closure scope

          nested =  begin
                      Nested.!(current, &cb)
                    rescue Errors::AnonymousTypeDetected => err
                      Utils.Type err.type
                    end

          name.nil? ? schema { each(nested) } : schema { __send__(current, name).each(nested) }

          define_method(name) { @inputs[name] } unless Nested === self
        end

        ########################################################################
        ### custom types
        ########################################################################

        def duck name, **params
          current = @current # closure scope
          filled_or_maybe = optionality(params)

          schema do
            __send__(current, name).__send__(filled_or_maybe, duck?: [*params[:methods]])
          end
        end

        # possible params: `class: nil, builder: nil, new_records: false`
        def model name, **params
          current = @current # closure scope
          filled_or_maybe = optionality(params)
          params[:class] ||= name.to_s.gsub(/(?:\A|_)./) { |m| m[-1].upcase }

          schema do
            __send__(current, name).__send__(filled_or_maybe, model?: params[:class])
          end
        end

        ########################################################################
        ### generic types
        ########################################################################

        def generic_type name = nil, **params
          fail Errors::AnonymousTypeDetected.new(__callee__) if name.nil?

          params = @environs.merge params if @environs

          # FIXME: :strip => true and siblings should be handled with procs?
          current = @current # closure scope

          opts = Utils.Guards(params)

          type = [optionality(params), Utils.Type(__callee__)]

          schema do
            Utils.smart_send(__send__(current, name), *type, **opts)
          end

          unless Nested === self
            define_method(name) { @inputs[name] }
            define_method(:"#{name}_present?") { @inputs.key?(name) }
            define_method(:"#{name}=") { |value| @inputs[name] = value }
          end
        end

        %i(string integer float date time boolean).each do |m|
          alias_method m, :generic_type
        end

        private :generic_type

        private

        def optionality nils
          # rubocop:disable Style/NestedTernaryOperator
          (nils.is_a?(Hash) ? nils[:nils] || nils[:empty] : nils) ? :maybe : :filled
          # rubocop:enable Style/NestedTernaryOperator
        end
      end
    end
  end
end
