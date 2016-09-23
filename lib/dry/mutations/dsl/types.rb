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
        def hash name, **params, &cb
          current = @current # closure scope

          schema { __send__(current, name).schema(Nested.!(current, &cb)) }

          case
          when params[:discard_empty] then schema.discarded!(name)
          when Nested === self then # do nothing
          else define_method(name) { Utils::Hash(@inputs[name]) }
          end
        end

        # FIXME: array of anonymous objects
        def array name, **params, &cb
          current = @current # closure scope

          nested =  begin
                      Nested.!(current, &cb)
                    rescue Errors::AnonymousTypeDetected => err
                      Utils.Type err.type
                    end

          name.nil? ? schema { each(nested) } : schema { __send__(current, name).each(nested) }

          case
          when params[:discard_empty] then schema.discarded!(name)
          when Nested === self then # do nothing
          else define_method(name) { @inputs[name] }
          end
        end

        ########################################################################
        ### custom types
        ########################################################################

        def duck name, **params
          # <<- CLOSURE_SCOPE
          current = @current
          params = @environs.merge params if @environs
          filled_or_maybe = optionality(params)
          # CLOSURE_SCOPE

          schema do
            __send__(current, name).__send__(filled_or_maybe, duck?: [*params[:methods]])
          end

          define_helper_methods name
        end

        # possible params: `class: nil, builder: nil, new_records: false`
        def model name, **params
          # <<- CLOSURE_SCOPE
          current = @current # closure scope
          params = @environs.merge params if @environs
          filled_or_maybe = optionality(params)
          params[:class] ||= name.to_s.gsub(/(?:\A|_)./) { |m| m[-1].upcase }
          # CLOSURE_SCOPE

          schema do
            __send__(current, name).__send__(filled_or_maybe, model?: params[:class])
          end

          define_helper_methods name
        end

        ########################################################################
        ### generic types
        ########################################################################

        def generic_type name = nil, **params
          fail Errors::AnonymousTypeDetected.new(__callee__) if name.nil?

          # <<- CLOSURE_SCOPE
          current = @current # closure scope
          params = @environs.merge params if @environs
          type = [optionality(params), Utils.Type(__callee__)]
          opts = Utils.Guards(params)
          # CLOSURE_SCOPE

          schema do
            Utils.smart_send(__send__(current, name), *type, **opts)
          end

          params[:discard_empty] ? schema.discarded!(name) : define_helper_methods(name)
        end

        %i(string integer float date time boolean).each do |m|
          alias_method m, :generic_type
        end

        private :generic_type

        private

        def optionality params
          # FIXME: Should we treat `empty?` in some specific way?
          params.delete(:nils) || params.delete(:empty) || params[:discard_empty] ? :maybe : :filled
        end

        def define_helper_methods name
          unless Nested === self
            define_method(name) { @inputs[name] }
            define_method(:"#{name}_present?") { @inputs.key?(name) }
            define_method(:"#{name}=") { |value| @inputs[name] = value }
          end
        end
      end
    end
  end
end
