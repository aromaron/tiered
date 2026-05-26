# Contributing to Tiered

Bug reports and pull requests are welcome on GitHub at https://github.com/aromaron/tiered.

## Getting started

```bash
git clone https://github.com/aromaron/tiered.git
cd tiered
bin/setup        # install dependencies
bundle exec rake test  # run the test suite
```

## Making changes

1. Fork the repo and create a branch from `main`.
2. Add tests for any new behaviour — the test suite lives in `test/`.
3. Make sure `bundle exec rake test` passes.
4. Update `CHANGELOG.md` under `## [Unreleased]`.
5. Update `README.md` if you changed a public API.
6. Open a pull request.

## Reporting bugs

Please use the [GitHub issue tracker](https://github.com/aromaron/tiered/issues).
Include the gem version, Ruby version, Rails version, and a minimal reproduction script.

## Code of Conduct

Everyone participating is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
