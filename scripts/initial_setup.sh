# Install homebrew if it's missing...
command -v brew >/dev/null 2>&1 || { echo >&2 "No hombrew detected, installing..."; \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
    echo -e "eval \"$(/opt/homebrew/bin/brew shellenv)\"" >> $HOME/.zshrc \
    eval "$(/opt/homebrew/bin/brew shellenv)"; }

# Setup prerequisites
brew install postgresql
brew install rbenv
rbenv install `cat .ruby-version`

# Setup the app
cp config/database.yml.example config/database.yml
bundle install
RAILS_ENV=production bundle exec rake db:create
RAILS_ENV=production bundle exec rake db:migrate
touch log/production.log

echo "Run 'thor list' to see available commands."
