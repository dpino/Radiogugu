RadioGugu
=========


Worldwide directory of radio stations.

Originally developed on Rails 2/3; modernized to run on Ruby 3.2 / Rails 7.1.

## Running locally

```
bundle config set --local path 'vendor/bundle'
bundle install
bin/rails db:setup      # creates storage/development.sqlite3 and runs migrations
bin/rails server
```

Then open http://localhost:3000.
