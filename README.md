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
          integer :days # For spot or forward_days options
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

### Turn On Globally (use with caution!)

    ENV['GLOBAL_DRY_MUTATIONS'] = 'true' && rake

That way _all_ mutations all over the system will be patched/injected with
new functionality. This is untested in all possible environments.

Bug reports are very welcome!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dry-mutations. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
