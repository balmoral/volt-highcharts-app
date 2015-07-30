# By default Volt generates this controller for your Main component

module Main
  class MainController < Volt::ModelController

    def chart_id
      'chart1'
    end

    def chart_options
      @chart_options ||= {
        # used by volt-highcharts component to identity chart on page, not by highcharts itself
        id: chart_id,

        # following are for highcharts
        chart: {
          type: 'bar'
        },
        title: {
          text: 'Fruit Consumption'
        },
        xAxis: {
          categories: %w(Apples Bananas Oranges Watermelons)
        },
        yAxis: {
          title: {
              text: 'Fruit eaten'
          }
        },
        series: [
          {
            name: 'Jane',
            data: [1, 0, 4, 0.5]
          },
          {
            name: 'John',
            data: [5, 7, 3, 0.25]
          },
          {
            name: 'Jack',
            data: [3, 5, 7, 0.33]
          },
          {
            name: 'Jill',
            data: [2, 1, 3, 0.1]
          }
        ]
      }
    end

    def chart
      @chart ||= Native(page._charts.detect { |e| e._id == chart_id }._chart)
    end

    def update_chart
      use_native = false
      if use_native
        chart_series = Native(chart.series)
        chart_options[:series].each_with_index do |series, i|
          Native(chart_series[i]).setData(series[:data].to_n)
        end
      else
        native_chart = chart.to_n
        Volt.logger.debug("#{self.class.name}##{__method__} : native_chart=#{native_chart}")
        chart_options[:series].each_with_index do |series, i|
          native_data = series[:data].to_n
          `native_chart.series[i].setData(native_data)`
        end
      end
    end

    def update_series
      Volt.logger.debug("#{self.class.name}##{__method__} : #{Time.now}")
      chart_options[:series].each do |series|
        series[:data] = [rand(10), rand(10), rand(10), (rand(8) / 4).to_f]
      end
      update_chart
    end

    def index
      Volt.logger.debug("#{self.class.name}##{__method__} : #{Time.now}")
      self.model = chart_options
      @poll_interval =  10
      poll
    end

    def before_index_remove
      @chart =  nil
    end

    def stop_poll
      if RUBY_PLATFORM == 'opal' && @js_interval
        Volt.logger.info("#{self.class.name}##{__method__} : calling javascript clearInterval(#{@interval})")
        `clearInterval(#{@js_interval})`
        @js_interval = nil
      end
    end

    def poll
      if RUBY_PLATFORM == 'opal'
        unless @js_interval
          Volt.logger.debug("#{self.class.name}##{__method__} : calling javascript setInterval")
          @js_interval = `setInterval(
              function() {
                var d = new Date();
                var s = (d.getHours() * 3600) + (d.getMinutes() * 60) + d.getSeconds();
                if ((s % #{@poll_interval}) == 0) {`
                  update_series
                `};
              },
              1000
            );`
        end
      end
    end

    def before_show_remove
      stop_poll
    end

    def about
      %q(A simple example using the volt-highcharts component to provide Highcharts functionality.

        https://rubygems.org/gems/volt-highcharts
      )
    end

    private

    # The main template contains a #template binding that shows another
    # template.  This is the path to that template.  It may change based
    # on the params._component, params._controller, and params._action values.
    def main_path
      "#{params._component || 'main'}/#{params._controller || 'main'}/#{params._action || 'index'}"
    end

    # Determine if the current nav component is the active one by looking
    # at the first part of the url against the href attribute.
    def active_tab?
      url.path.split('/')[1] == attrs.href.split('/')[1]
    end
  end
end
