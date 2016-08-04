module Kernel # :nodoc:
  def Outcome input
    ::Dry::Mutations::Extensions.Outcome(input)
  end

  def Outcome! input
    ::Dry::Mutations::Extensions.Outcome!(input)
  end

  def Schema(options = {}, &block)
    ::Dry::Validation.Schema(::Dry::Mutations::DSL.Schema(), options, &block)
  end
end
