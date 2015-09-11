# By default Volt generates this controller for your Main component

module Main
  class MainController < Volt::ModelController

    attr_reader :type, :speed, :animate
    attr_reader :types, :select_types, :select_speeds
    attr_reader :non_area_types

    def options
      @options ||= Volt::Model.new({

        # Used by volt component to identify chart on page.
        id: 'random',

        # Used by volt component to determine chart mode:
        #   :chart for Highcharts
        #   :stock for Highstock
        #   :map   for Highmaps
        mode: :chart,

        # Used by volt component as global setting for chart animation.
        animate: animate,

        # Following options are passed to Highcharts:
        # see http://api.highcharts.com/highcharts
        chart:    { renderTo:   'chart'           },
        title:    { text:       title             },
        subtitle: { text:       subtitle          },
        xAxis:    { categories: category_labels   },
        yAxis:    { title:      { text: 'VALUE' } },
        series:   series,
        tooltip:  false
      })
    end

    def index
      @animate = false
      @type ||= 'scatter'
      @types = %w(column spline areaspline scatter bubble line area).sort!
      @non_area_types = %w(column line spline scatter bubble).sort!
      @select_types = @types + %w(mix remix)
      @speeds = {'rapid' => 50, 'fast' => 100, 'medium' => 500, 'slow' => 1000, 'pause' => 0 }
      @select_speeds = @speeds.keys
      self.speed = 'fast'
      self.model = options
      @count = 0
      poll
    end

    def speed=(speed)
      @speed = speed
      @interval = @speeds[@speed]
      update_chart(:all) if @interval == 0
    end

    def before_index_remove
      @interval = 0
      stop_poll
    end

    def animate=(value)
      suspend_poll do
        @animate = value
        options._animate = @animate
      end
    end

    def type=(type)
      @type = type
      update_chart(:type)
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

    def update_chart(what)
      suspend_poll do
        # debug __method__, __LINE__, "what=#{what}"
        case what
          when :type
            @count = 1
            options._series.each do |series|
              series._type = @type =~ /mix/ ? random_type : type
            end
          else
            @count += 1
            options._series.sample._data = random_data
        end
        options._title._text = title
        options._subtitle._text = subtitle
      end
    end

    def suspend_poll
      p = @interval
      @interval = 0
      yield
      @interval = p
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
                if (#{@interval} > 0 && (#{@millisecs} % #{@interval}) == 0) {`
                  update_chart(:data)
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

    def random_val
      rand(90) + 2
    end

    def random_type
      non_area_types.sample
    end

    def random_data
      n_categories.times.collect { random_val }
    end

    def category_labels
      n_categories.times.collect { |i| "X#{i+1}" }
    end

    def series
      n_series.times.collect do |i|
        {
          type: 'scatter',
          name: "S#{i+1}",
          data: random_data
        }
      end
    end

    def title
      if speed == 'pause'
        "#{type.upcase} ##{@count}"
      else
        "#{speed.upcase} #{type.upcase} ##{@count}"
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
