# BitmaskEnum changelog

## 0.1.0 : 2022-08-28

Initial build. Pre-release.

Checking and setting of flags on model instance.
Scopes for querying.

## 0.2.0 : 2022-08-28

Pre-release.

Refactor of underlying logic. 
Enforce symbols in method output.

## 0.3.0 : 2022-08-28

Pre-release.

Refactor logic and tests.
Switch bitmask_enum params to a single hash with multiple keys.

## 0.4.0 : 2022-08-28

Pre-release.

Add nil handling.
Refactor options and add testing for them.

## 1.0.0 : 2022-08-29

Release.

Add setter override to write flags as flag values.
Add YARD docs.
Standardize output to symbols.
Add validation of the attribute - less_than: 1 << flags.size
Add max ActiveRecord version to protect against future breaking releases

# 1.1.0 : 2022-08-30

Add dynamic scopes for any of provided flags enabled or disabled.
Add dynamic scopes for all of provided flags enabled or disabled.
Correct and update some documentation.

# 1.1.1 : 2022-08-30

Dependencies changes for development concerns.
