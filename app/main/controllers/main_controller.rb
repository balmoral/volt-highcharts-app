# By default Volt generates this controller for your Main component

module Main
  class MainController < Volt::ModelController

    attr_reader :chart_type, :chart_speed, :chart_animated
    attr_reader :chart_types, :select_types, :select_speeds
    attr_reader :non_area_chart_types

    def chart_options
      @chart_options ||= Volt::Model.new({

        # Used by volt component to identity chart on page.
        # Not used by Highcharts.
        id: 'random',

        # Set chart mode:
        #   :chart for Highcharts
        #   :stock for Highstock
        #   :map   for Highmaps
        mode: :chart,

        # Set whether data redraws should be animated
        animate: chart_animated,

        # Following are for Highcharts:
        # http://api.highcharts.com/highcharts
        #
        chart:    { renderTo:   'chart'           },
        title:    { text:       chart_title       },
        subtitle: { text:       subtitle          },
        xAxis:    { categories: category_labels   },
        yAxis:    { title:      { text: 'VALUE' } },
        series:   series,
        tooltip:  false
      })
    end

    def index
      @chart_animated = true

      @chart_type ||= 'scatter'
      @chart_types = %w(column spline areaspline scatter bubble line area).sort!
      @non_area_chart_types = %w(column line spline scatter bubble).sort!
      @select_types = @chart_types + %w(mix remix)

      @select_speeds = %w(rapid fast medium slow pause)
      self.chart_speed = 'fast'

      self.model = chart_options
      @rand_count = 0
      poll
    end

    def chart_speed=(speed)
      @chart_speed = speed
      # milliseconds
      @poll_interval = case @chart_speed
        when 'pause'    then    0
        when 'rapid'    then   50
        when 'fast'     then  100
        when 'medium'   then  500
        when 'slow'     then 1000
        when 'slow'     then 2000
        else
          raise RuntimeError, "invalid chart speed '#{@chart_speed}'"
      end
      update_chart if @poll_interval == 0
    end

    def before_index_remove
      @poll_interval = 0
      stop_poll
    end

    def chart_animated=(value)
      suspend_poll do
        @chart_animated = value
        chart_options._animate = @chart_animated
      end
    end

    def chart_type=(type)
      @chart_type = type
      update_chart(true)
    end

    def select_speed_pairs
      select_speeds.map {|s| {label: s, value: s}}
    end

    def about
      %q(A whimsical demonstration of highly-reactive Ruby+Opal+Volt wrap of Highcharts JS.
      )
    end

    private

    def find_chart(id)
      page._charts.detect { |e| e._id == id }._chart
    end

    def update_chart(type_change = false)
      suspend_poll do
        @rand_count += 1
        if type_change
          chart_options._series.each {|s| s._type = @chart_type =~ /mix/ ? rand_type : @chart_type}
        else
          # chart_options._series.sample._data = series_data
          chart_options._series.sample._data = series_data
        end
        chart_options._title._text = chart_title
        chart_options._subtitle._text = subtitle
      end
    end

    def suspend_poll
      p = @poll_interval
      @poll_interval = 0
      yield
      @poll_interval = p
    end

    def stop_poll
      if RUBY_PLATFORM == 'opal' && @js_interval
        `clearInterval(#{@js_interval})`
        @js_interval = nil
      end
    end

    def poll
      if RUBY_PLATFORM == 'opal'
        @millisecs = 0
        unless @js_interval
          @js_interval = `setInterval(
              function() {
                if (#@millisecs == 1000000) {
                  #{@millisecs} = 0
                };
                #{@millisecs} += 50;
                if (#{@poll_interval} > 0 && (#{@millisecs} % #{@poll_interval}) == 0) {`
                  update_chart
                `};
              },
              50
            );`
        end
      end
    end

    def n_categories
      10
    end

    def n_series
      9
    end

    def rand_val
      rand(90) + 2
    end

    def rand_type
      non_area_chart_types.sample
    end

    def series_data
      n_categories.times.collect { rand_val }
    end

    def category_labels
      n_categories.times.collect { |i| "X#{i+1}" }
    end

    def series
      n_series.times.collect do |i|
        {
          type: 'scatter',
          name: "S#{i+1}",
          data: series_data
        }
      end
    end

    def chart_title
      if chart_speed == 'pause'
        "#{chart_type.upcase} ##{@rand_count}"
      else
        "#{chart_speed.upcase} #{chart_type.upcase} ##{@rand_count}"
      end
    end

    def subtitle
      Time.now.to_s
    end

    def debug(_method, line, s = nil)
      Volt.logger.debug "#{self.class.name}##{_method}[#{line}] : #{s}"
    end

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
