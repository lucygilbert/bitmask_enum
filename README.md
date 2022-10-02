# BitmaskEnum

A bitmask enum attribute for ActiveRecord.

Aiming to be lightweight and performant, providing the core functionality for the use of a bitmask enum model attribute.

It adds checking, getting, setting and toggling of the flags to the instance; scopes for flags to the class; and allows creating/updating the attribute with a flag/an array of flags rather than an integer.

Supporting Ruby 2.4+ and Rails 4.2+.

Credit is due to Joel Moss' gem [bitmask_attributes](https://github.com/joelmoss/bitmask_attributes). I came across it while considering if I should write a gem for this. It's great work and some elements of it inspired this gem, I just had my own thoughts about how I'd like the gem to operate, and wanted some more end-to-end experience on gem production so I decided to create this rather than pick up the torch on that repo.

This gem attempts to improve performance by precomputing the integer values for the enum rather than using bitwise operations in the SQL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bitmask_enum'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bitmask_enum

## Usage

[RubyDocs for BitmaskEnum](https://www.rubydoc.info/github/lucygilbert/bitmask_enum/master)

In the model, the bitmask enum is added in a similar way to enums. Given an integer attribute called `attribs`, flags of `flag` and `flag2`, adding the `flag_prefix` option with the value `type`, the following line would be used:

```ruby
bitmask_enum attribs: [:flag, :flag2], flag_prefix: 'type'
```

The `bitmask_enum` class method is used to add the bitmask enum, which then goes on to add numerous helper methods to the model.

It also enables setting the attribute with a flag or array of flags when creating or updating. More info is in the `{attribute}=` method section.
```ruby
Model.create!(attribs: :flag)
Model.update!(attribs: [:flag, :flag2])
```

### `bitmask_enum`

`bitmask_enum params`

#### params

**Type:** Hash

The first key of this hash should be the name of the integer attribute to be modeled as a bitmask enum. The value of that key should be an array of symbols or strings representing the flags that will be part of the bitmask.

Any following keys are optional and should define options for the enum. The current accepted keys are:
- `flag_prefix` - A symbol or string that will prefix all the created method names for individual flags
  - The gem will prepend the provided value to the flag with an underscore, e.g. `pre` would become `pre_flag`
- `flag_suffix` - A symbol or string that will suffix all the created method names for individual flags
  - The gem will append the provided value to the flag with an underscore, e.g. `post` would become `flag_post`
- `nil_handling` - A symbol or string that signifies which behaviour to use when handling nil attribute values
  - The default value, used if the option is not supplied, is `:include`. This includes nil attribute rows as if they were 0.
  - There are currently no other options but more are planned.
  - Providing an unrecognized option will raise an error.
- `validate` - A boolean signaling whether you want to apply attribute validation. Attributes will validate that they are less than the number of flags squared (number of flags squared - 1 is the highest valid bitmask value). Defaults to `true`.

---

### The following methods will be created on the model instance:

### `{flag}?`

**No params**

For each flag, this method will be created.

The method checks whether a flag is enabled or not.

**Return value:** `boolean` - reflects whether the flag is enabled for the instance.

### `{flag}!`

**No params**

For each flag, this method will be created.

The method toggles the current setting of the flag.

**Return value:** `boolean` - true if the update of the attribute was successful. Raises error if update was unsuccessful.

### `enable_{flag}!`

**No params**

For each flag, this method will be created.

The method enables the the flag is it is disabled, otherwise it takes no action.

**Return value:** `boolean` - true if the update of the attribute was successful. Raises error if update was unsuccessful.

### `disable_{flag}!`

**No params**

For each flag, this method will be created.

The method disables the the flag is it is enabled, otherwise it takes no action.

**Return value:** `boolean` - true if the update of the attribute was successful. Raises error if update was unsuccessful.

### `{attribute}_settings`

**No params**

This method will be created once on the instance.

The method returns a hash with the flags as keys and their current settings as values. The keys will be symbols.

**Return value:** `hash` - hash with flags as keys and their current settings as values. E.g. `{ flag_one: true, flag_two: false }`

### `{attribute}` (_Override_)

**No params**

This method will be created once on the instance.

The method returns an array of all enabled flags on the instance. The items will be symbols. This is the attribute getter.

**Return value:** `array` - array of enabled flags. E.g. `[:flag_one, :flag_two]`

### `{attribute}=` (_Override_)

**Params**

- value [Integer, Symbol, String, Array\<Symbol, String\>] - An integer, a defined flag or array of defined flags

This method will be created once on the instance.

The method sets the attribute to the provided value - either an integer, a symbol or string representing a flag or an array of symbols or strings. This is the attribute setter.

This method will raise an ArgumentError if one of the flag values passed is not one that was defined.

**Return value:** `array` - array of enabled flags. E.g. `[:flag_one, :flag_two]`

---

### The following methods will be created on the model class:

### `{flag}_enabled`

**No params**

For each flag, this method will be created on the class.

The method is a scope of all records for which the flag is enabled.

**Return value:** `ActiveRecord::Relation` - a collection of all records for which the flag is enabled.

### `{flag}_disabled`

**No params**

For each flag, this method will be created on the class.

The method is a scope of all records for which the flag is disabled.

**Return value:** `ActiveRecord::Relation` - a collection of all records for which the flag is disabled.

### `no_{attribute}_enabled`

**No params**

This method will be created once on the class.

The method is a scope of all records for which no flags are enabled.

**Return value:** `ActiveRecord::Relation` - a collection of all records for which no flags are enabled.

### `any_{attribute}_enabled`

**Params**

- flags [Symbol, String, Array\<Symbol, String\>] - A defined flag or array of defined flags

This method will be created once on the class.

The method is a scope of all records for which any of the provided flags are enabled.

**Return value:** `ActiveRecord::Relation` - a collection of all records for which the flag is enabled.

### `any_{attribute}_disabled`

**Params**

- flags [Symbol, String, Array\<Symbol, String\>] - A defined flag or array of defined flags

This method will be created once on the class.

The method is a scope of all records for which any of the provided flags are disabled.

**Return value:** `ActiveRecord::Relation` - a collection of all records for which the flag is disabled.

### `all_{attribute}_enabled`

**Params**

- flags [Symbol, String, Array\<Symbol, String\>] - A defined flag or array of defined flags

This method will be created once on the class.

The method is a scope of all records for which all of the provided flags are enabled.

**Return value:** `ActiveRecord::Relation` - a collection of all records for which the flag is enabled.

### `all_{attribute}_disabled`

**Params**

- flags [Symbol, String, Array\<Symbol, String\>] - A defined flag or array of defined flags

This method will be created once on the class.

The method is a scope of all records for which all of the provided flags are disabled.

**Return value:** `ActiveRecord::Relation` - a collection of all records for which the flag is disabled.

### `{attribute}`

**No params**

This method will be created once on the class.

The method returns an array of all the defined flags. The items will be symbols.

**Return value:** `array` - array of defined flags. E.g. `[:flag_one, :flag_two]`

## Manual testing

This gem has been tested and found to be generally functional with the following combinations: (but it should work with any combination of Ruby 2.4+ and Rails 4.2+, theoretically it could go lower but those are already 8 years old so I felt it was sufficient.)

- Ruby 2.4.10 & Rails 4.2.11.3
- Ruby 2.6.10 & Rails 4.2.11.3
- Ruby 2.6.10 & Rails 5.2.8.1
- Ruby 3.1.2 & Rails 7.0.3.1

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lucygilbert/bitmask_enum. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

1. Fork the repo.
2. Run `bin/setup` to install the bundle and set up the pre-commit hook.
  - If the output ends with `SUCCESS.`, the pre-commit hook has been applied correctly.
  - If the output ends with `ERROR!`, applying the pre-commit hook has failed. Please check the error and install manually.
3. Create a branch, prefixed with `feature/` if this addition is a new feature, or `bugfix/` if the addition is a bug fix.
4. Add your code with ample testing and ensure that tests and linting pass for your commit.
5. Push the branch to your fork and raise a PR against the main repo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BitmaskEnum project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/bitmask_enum/blob/master/CODE_OF_CONDUCT.md).
