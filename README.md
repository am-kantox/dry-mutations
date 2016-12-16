# Dry::Mutations

[![Build Status](https://travis-ci.org/am-kantox/dry-mutations.svg?branch=master)](https://travis-ci.org/am-kantox/dry-mutations)
[![Code Climate](https://codeclimate.com/github/am-kantox/dry-mutations/badges/gpa.svg)](https://codeclimate.com/github/am-kantox/dry-mutations)

---

A link between [`dry-validation`](http://dry-rb.org/gems/dry-validation) and
[`mutations`](http://github.com/cypriss/mutations) gems. This gem enables
support for `dry-validation` schemas to be used within legacy `mutations`-based
syntax.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dry-mutations'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dry-mutations

## Was ⇒ Is

### Was

```ruby
class ComposedMutation < Mutations::Command
  ...
  def validate
    additional_validate(input1, input2)
    @nested = NestedMutation.new(inputs, input1: input1, input2: input2)
    unless @nested.validation_outcome.success?
      @nested.validation_outcome.errors.each do |key, error|
        add_error(key.to_sym, error.symbolic, error.message)
      end
    end
  end

  def execute
    @nested.run!
  end
end
```

### Is
```ruby
class ComposedValidation < Mutations::Command
  prepend ::Dry::Mutations::Extensions::Command
  prepend ::Dry::Mutations::Extensions::Dummy

  ...
  def validate
    additional_validate(input1, input2)
  end
end

class ComposedTransform < Mutations::Command
  prepend ::Dry::Mutations::Extensions::Command

  ...
  def execute
    inputs.merge(input1: input1, input2: input2)
  end
end

class ComposedMutation
  extend ::Dry::Mutations::Transactions::DSL
  chain do
    validate ComposedValidation
    transform ComposedTransform
    mutate NestedMutation
  end
end
```

### Call syntax

Basically, any call syntax is supported:

```ruby
# preferred
ComposedMutation.(input)          # returns (Either ∨ Outcome) object

# legacy
ComposedMutation.run(input)       # returns (Either ∨ Outcome) object
ComposedMutation.new(input).run   # returns (Either ∨ Outcome) object
ComposedMutation.run!(input)      # throws Mutation::ValidationException
ComposedMutation.new(input).run!  # throws Mutation::ValidationException
```

## Usage

### Enable extensions for the specific mutation’s command

Prepend a `::Dry::Mutations::Extensions::Command` module to your `Mutation::Command` instance:

```ruby
class MyMutation < Mutations::Command
  prepend ::Dry::Mutations::Extensions::Command

  required do
    model :company, class: 'Profile'
    model :user
    hash  :maturity_set do
      string :maturity_choice, in: %w(spot forward_days fixed_date)
      optional do
        hash :maturity_days_set do
          integer :days, default: 3 # For spot or forward_days options
        end
        hash :maturity_date_set do
          date :date # When passing a fixed date
        end
      end
    end
    ...
```

### `dry-validation` syntax

It is possible to mix standard mutations’ syntax with `dry-rb` schemas:

```ruby
class MyMutation < Mutations::Command
  prepend ::Dry::Mutations::Extensions::Command

  required do
    model :company, class: 'Profile'
  end

  schema do
    required(:maturity_choice).filled(:str?, included_in?: %w(spot forward_days fixed_date))
  end
```

### Reusing schema

Basically, everything [written here](http://dry-rb.org/gems/dry-validation/reusing-schemas/)
is applicable. Syntax to include the nested schema is as simple as:

```ruby
UserSchema = Dry::Validation.Schema do
  required(:email).filled(:str?)
  required(:name).filled(:str?)
  required(:address).schema(AddressSchema)
end
```

or, in legacy `mutations` syntax (**NB! This is not yet implemented!**):

```ruby
required do
  string :email
  string :name
  schema :address, AddressSchema
end
```

## Combining dry schemas with mutation-like syntax

Since version `0.11.1`, one might pass the instance of `Dry::Validation::Schema`
and/or `Dry::Validation::Form` instance to `schema` mutation DSL. Such a block
might be _only one_, and it _must be_ the first DSL in the mutation:

### Correct

```ruby
Class.new(::Mutations::Command) do
  prepend ::Dry::Mutations::Extensions::Command
  prepend ::Dry::Mutations::Extensions::Sieve

  schema(::Dry::Validation.Form do
    required(:integer_value).filled(:int?, gt?: 0)
    required(:date_value).filled(:date?)
    required(:bool_value).filled(:bool?)
  end)

  required do
    integer :forty_two
    string :hello
  end
end
```

### Incorrect

```ruby
Class.new(::Mutations::Command) do
  prepend ::Dry::Mutations::Extensions::Command
  prepend ::Dry::Mutations::Extensions::Sieve

  required do
    integer :forty_two
    string :hello
  end

  schema(::Dry::Validation.Form do
    required(:integer_value).filled(:int?, gt?: 0)
    required(:date_value).filled(:date?)
    required(:bool_value).filled(:bool?)
  end)
end
```

## Dealing with `outcome`

### Command

```ruby
let!(:command) do
  Class.new(::Mutations::Command) do
    prepend ::Dry::Mutations::Extensions::Command

    required { string :name, max_length: 5 }
    schema { required(:amount).filled(:int?, gt?: 0) }

    def execute
      @inputs
    end
  end
end
```

### Using `Either` monad

```ruby
outcome = command.new(name: 'John', amount: 42).run
outcome.right?
#⇒ true
outcome.either.value
#⇒ { 'name' => 'John', 'amount' => 42 }

outcome = command.new(name: 'John Donne', amount: -500).run
outcome.right?
#⇒ false
outcome.left?
#⇒ true
outcome.either
#⇒ Left({
#   "name"=>#<Dry::Mutations::Errors::ErrorAtom:0x00000003b4e7b0
#               @key="name",
#               @symbol=:max_length,
#               @message="size cannot be greater than 5",
#               @index=0,
#               @dry_message=#<Dry::Validation::Message
#                               predicate=:max_size?
#                               path=[:name]
#                               text="size cannot be greater than 5"
#                               options={:args=>[5], :rule=>:name, :each=>false}>>,
#   "amount"=>#<Dry::Mutations::Errors::ErrorAtom:0x00000003b4e508
#               @key="amount",
#               @symbol=:gt?,
#               @message="must be greater than 0",
#               @index=1,
#               @dry_message=#<Dry::Validation::Message
#                               predicate=:gt?
#                               path=[:amount]
#                               text="must be greater than 0"
#                               options={:args=>[0], :rule=>:amount, :each=>false}>>
# })
outcome.either.value
#⇒ the hash ⇑ above
```

### Using `Matcher`

```ruby
expect(outcome.match { |m| m.success(&:keys) }).to match_array(%w(amount name))
expect(outcome.match { |m| m.failure(&:keys) }).to be_nil
```

## Turn On Globally (use with caution!)

    ENV['GLOBAL_DRY_MUTATIONS'] = 'true' && rake

That way _all_ mutations all over the system will be patched/injected with
new functionality. This is untested in all possible environments.

Bug reports are very welcome!

## Changelog

#### 0.99.1
Support for direct input parameters invocation. 100%-compatibility with `mutations`:

```ruby
def validate # input ≡ { date: nil }
  date < Date.now
end
```

#### 0.99.0
Support for `default:` guard. 99%-compatibility with `mutations`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dry-mutations. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
