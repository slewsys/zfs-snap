# frozen_string_literal: true

require 'date'
require 'time'

##
# IO class.
class IO
  ##
  # Singleton of IO class.
  class << self
    # Mask given I/O streams.
    def mask(*streams)
      saved_streams = streams.collect(&:dup)
      streams.each do |stream|
        stream.reopen('/dev/null')
        stream.sync = true
      end
      yield
    ensure
      streams.each_with_index do |stream, i|
        stream.reopen(saved_streams[i])
      end
    end
  end
end

##
# Module ZFS
module ZFS
  ZFS_PATH = case RbConfig::CONFIG['host_os']
             when /linux/, /freebsd/
               '/sbin/zfs'
             when /solaris/
               '/usr/sbin/zfs'
             end

  ##
  # Singleton of ZFS class.
  class << self
    # Return true if given dataset exists and is a snapshot, otherwise false.
    def snapshot?(dataset)
      # Work around Linux ZFS issue where the command:
      #     zfs list -type snapshot dataset
      # succeeds if dataset exists but is not a snapshot.
      return false if dataset.index('@').nil?

      IO.mask($stdout, $stderr) do
        system ZFS_PATH, 'list', '-t', 'snapshot', dataset
      end
    end

    # Return true if given dataset exists.
    def dataset?(dataset)
      IO.mask($stdout, $stderr) do
        system ZFS_PATH, 'list', dataset
      end
    end

    # Return type of given dataset.
    def type_of?(dataset)
      if snapshot?(dataset)
        :snapshot
      elsif dataset?(dataset)
        :dataset
      else
        :unknown
      end
    end
  end

  ##
  # Module ZFS::Snap
  module Snap
    SECONDS = {
      d: 86_400,
      w: 604_800,
      m: 2_592_000,
      y: 31_536_000,
      H: 3600,
      M: 60,
      S: 1
    }.freeze

    FREQUENCIES = %i[hourly daily weekly monthly].freeze

    DEFAULTS = { frequency: 'hourly', lifespan: '2w' }.freeze

    ##
    # Singleton class of ZFS::Snap
    class << self
      # Iterate over ZFS snapshots.
      def each
        IO.popen([ZFS_PATH, 'list', '-H', '-t', 'snapshot'],
                 err: %i[child out]) do |io|
          io.readlines.map { |line| line.split[0] }.each do |snapshot|
            yield Dataset.new(snapshot)
          end
        end
      end

      # Match given PATTERN against ZFS snapshots.
      def scan(pattern)
        IO.popen([ZFS_PATH, 'list', '-H', '-t', 'snapshot'],
                 err: %i[child out]) do |io|
          io.readlines.map { |line| line.split[0] }.map do |snapshot|
            Dataset.new(snapshot) if snapshot =~ /#{pattern}/
          end.compact
        end
      end

      # Validate given frequency argument FREQ.
      def validate_frequency(freq)
        unless FREQUENCIES.include? freq.to_sym
          $err_status = 1
          raise ArgumentError,
                "#{freq}: Invalid frequency - expecting: #{FREQUENCIES.join('|')}"
        end
        freq
      end

      # Validate given lifespan argument SPAN.
      def validate_lifespan(span)
        if span !~ /^[[:digit:]]+[#{SECONDS.keys.join}]$/
          $err_status = 1
          raise ArgumentError,
                "#{span}: Invalid lifespan - expecting: [[:digit:]]+[#{SECONDS.keys.join}]}"
        end
        span
      end

      # Return hash of validated arguments.
      def validate_params(freq, span)
        {
          frequency: validate_frequency(freq),
          lifespan: validate_lifespan(span)
        }
      end
    end

    ##
    # Class ZFS::Snap::Dataset
    class Dataset
      attr_reader :name

      def initialize(dataset, params: DEFAULTS, ui_module: :Console)
        # Include ui_module to expose `respond' and `error' methods...
        self.class.include((Object.const_get ui_module))

        case ZFS.type_of? dataset
        when :snapshot
          @name = dataset
        when :dataset
          stamp = Time.now.utc.iso8601.gsub(/-|:/, '')
          @name = "#{dataset}@#{params[:frequency]}-#{stamp}--#{params[:lifespan]}"
        else
          error "#{dataset}: Invalid ZFS dataset"
          @name = nil
        end
      end

      def expired?
        return unless /(?<ts>\d+T\d+Z)--(?<age>\d+)(?<span>\w+)/ =~ name

        origin = DateTime.strptime(ts, '%Y%m%dT%H%M%S%z').to_time
        Time.now >= origin + age.to_i * SECONDS[span.to_sym]
      end

      def create(request)
        command = [ZFS_PATH, 'snap']
        command.append '-r' if request[:recursively]
        command.append name
        respond command.join(' ') if request[:verbose]
        return if request[:no_exec]

        status = IO.mask($stdout, $stderr) do
          system(*command) unless request[:no_exec]
        end
        result = "#{name}: #{status ? 'created' : 'create failed'}"
        respond request[:recursively] ? "#{result} (recursively)" : result
      end

      def destroy(request)
        command = [ZFS_PATH, 'destroy']
        command.append '-r' if request[:recursively]
        command.append name
        respond command.join(' ') if request[:verbose]
        return if request[:no_exec]

        status = IO.mask($stdout, $stderr) do
          system(*command)
        end
        result = "#{name}: #{status ? 'destroyed' : 'destroy failed'}"
        respond request[:recursively] ? "#{result} (recursively)" : result
      end
    end
  end
end
