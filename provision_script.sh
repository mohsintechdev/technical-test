#!/bin/bash
#set -x

# install dependencies
sudo apt-get update && sudo apt-get install -y curl gnupg2 apt-transport-https ca-certificates software-properties-common

# Install RVM (Ruby Version Manager) and Ruby
curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm install 3.1.2
rvm use 3.1.2 --default

# Install Rails
gem install rails -v 7.0.4

# Install Node.js
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn

# Install psql service
sudo apt-get install -y postgresql postgresql-contrib libpq-dev

# Start psql and create a user and database
sudo service postgresql start
sudo -u postgres createuser --superuser rails_user
sudo -u postgres psql -c "ALTER USER rails_user PASSWORD 'password';"
sudo -u postgres createdb hello_world_development -O rails_user

# Install Redis
sudo apt-get install -y redis-server

# Install monitoring tools (Prometheus, Grafana, and node_exporter)
# Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.37.0/prometheus-2.37.0.linux-amd64.tar.gz
tar xvfz prometheus-2.37.0.linux-amd64.tar.gz
cd prometheus-2.37.0.linux-amd64
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo cp -r consoles /etc/prometheus/
sudo cp -r console_libraries /etc/prometheus/
sudo cp prometheus.yml /etc/prometheus/prometheus.yml

# Node exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
cd node_exporter-1.3.1.linux-amd64
sudo cp node_exporter /usr/local/bin/

# Grafana
sudo apt-get install -y adduser libfontconfig1
wget https://dl.grafana.com/oss/release/grafana_8.4.5_amd64.deb
sudo dpkg -i grafana_8.4.5_amd64.deb

# Enable and start services
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Create a new Rails application
rails new hello_world --database=postgresql
cd hello_world

# Configure database
sed -i "s/username: .*/username: rails_user/" config/database.yml
sed -i "s/password:.*/password: 'password'/" config/database.yml

# Create and migrate the database
rails db:create
rails db:migrate

# Add Redis gem to Gemfile
echo "gem 'redis'" >> Gemfile
bundle install

# Set up Redis in Rails
cat <<EOL >> config/initializers/redis.rb
require 'redis'

$redis = Redis.new(host: 'localhost', port: 6379)
EOL

# Generate a simple controller for Hello World
rails generate controller Welcome index

# Update routes
echo "root 'welcome#index'" >> config/routes.rb

# Create a view for Welcome#index
cat <<EOL > app/views/welcome/index.html.erb
<h1>Hello, World!</h1>
EOL

# Run the Rails server
rails server
