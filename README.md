Example app using volt-highcharts component available at:
 
https://github.com/balmoral/volt-highcharts
 
and
 
https://rubygems.org/gems/volt-highcharts

# Volt::Highcharts

A Volt component wrapping the Highcharts javascript charting tool.

Highcharts is free for non-commercial use.

http://www.highcharts.com/products/highcharts

# Heroku

http://docs.voltframework.com/en/deployment/heroku.html
 
Install the heroku tool belt. 
Adjust gem file per the Volt docs (and below).
Commit to git local. 
exec: heroku create
exec: git push heroku master 
For Mongo connection use Mongolab's free option.
Run heroku addons:create mongolab to activate the plugin.
Adjust app.rb as per the volt heroku documentation 
(using ENV['MONGOLAB_URI'] instead of the ENV['MONGOHQ_URL']). 
This will allow you to use your local Mongo database for 
development and the MONGOLAB for the production release on Heroku.