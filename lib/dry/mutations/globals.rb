module Kernel # :nodoc:
  def Outcome input
    ::Dry::Mutations::Extensions.Outcome(input)
  end

  def Outcome! input
    ::Dry::Mutations::Extensions.Outcome!(input)
  end

  def Schema(input_processor: nil, **options, &block)
    ::Dry::Mutations.Schema(input_processor: input_processor, **options, &block)
  end
end
