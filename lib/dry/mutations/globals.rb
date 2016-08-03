module Kernel # :nodoc:
  def Outcome input
    ::Dry::Mutations::Extensions.Outcome(input)
  end

  def Outcome! input
    ::Dry::Mutations::Extensions.Outcome!(input)
  end

  def Schema
    ::Dry::Mutations::DSL.Schema()
  end
end
