# Well, I expect tons of questions about this.
# Just let it stay, unless I understand the cause of exception thrown
#   in this particular case.

# rubocop:disable Style/ClassAndModuleChildren
class Dry::Logic::Rule::Value < Dry::Logic::Rule
  def input
    predicate.args.last rescue nil
  end
end
# rubocop:enable Style/ClassAndModuleChildren
