module Dry
  module Mutations
    module DSL
      module Blocks # :nodoc:
        def optionality
          @current = __callee__
          instance_eval(&Proc.new) if block_given?
          @current = nil
        end

        alias_method :optional, :optionality
        alias_method :required, :optionality

        private :optionality

        # with_options empty: true do |empty|
        #   empty.string :bank_reference, nils: true
        #   empty.array  :invoice_files,  nils: true
        # end
        # FIXME: UNFINISHED
        def with_options **params
          @environs = params
          instance_eval(&Proc.new) if block_given?
          @environs = nil
        end
      end
    end
  end
end
