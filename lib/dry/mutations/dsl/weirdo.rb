module Dry
  module Mutations
    module DSL
      module Weirdo # :nodoc:
        # FIXME: try-catch and call super in rescue clause
        def method_missing m, *args, &cb
          puts "==> [MM] “#{m}” called with args: “#{args.inspect}”"
          name, current = args.shift, @current
          schema do
            configure do
              define_method(:"#{name}?") do |value|
                false # FIXME
              end
            end

            __send__(current, name) { __send__ :"#{name}?" }
          end
        end
      end
    end
  end
end
