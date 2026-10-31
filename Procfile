# Heroku. One web dyno runs Puma with the Solid Queue supervisor inside it (the plugin in
# config/puma.rb). When exports should not share the web dyno, drop the variable and add
#   worker: bin/jobs
web: SOLID_QUEUE_IN_PUMA=1 bin/rails server
release: bin/rails db:migrate
