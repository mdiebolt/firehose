require 'goliath'
require 'goliath/websocket'

module Firehose
  module Goliath
    class WebSocket < ::Goliath::WebSocket
      use ::Goliath::Rack::Params

      def on_open(env)
        # TODO Fix the Firehose::App app to not need '/ws' in front of the socket.
        path    = env['REQUEST_PATH'].gsub(/^\/ws/, '') # Name of the queue in AMQP we'll be pulling from.
        cid     = params[:cid]

        @subscription = Firehose::Subscription.new(cid)
        @subscription.subscribe path do |payload|
          env.stream_send(payload)
        end
      end

      def on_close(env)
        @subscription.unsubscribe if @subscription
      end
    end

    class LongPolling < ::Goliath::API
      use ::Goliath::Rack::Params

      def response(env)
        method  = env['REQUEST_METHOD'] # We use this to figure out if we're producing or consuming.
        path    = env['REQUEST_PATH'] # Name of the queue in AMQP we'll be pulling from.
        cid     = params[:cid]

        case method
        # GET is how clients subscribe to the queue. When a messages comes in, we flush out a response,
        # close down the requeust, and the client then reconnects.
        when 'GET'
          subscription = Firehose::Subscription.new(cid)
          subscription.subscribe path do |payload|
            subscription.unsubscribe
            env.chunked_stream_send(payload)
            env.chunked_stream_close
          end
          chunked_streaming_response(200, 'Content-Type' => 'text/plain')
        # PUT is how we throw messages on to the fan-out queue.
        when 'PUT'
          body = env['rack.input'].read
          p [:put, path, body]
          Firehose::Publisher.new.publish(path, body)

          [202, {}, []]
        else
          [501, {}, ["#{method} not supported."]]
        end
      end

    private
      def self.connection
        @connection ||= AMQP.connect
      end
    end

    class App < ::Goliath::API
      # TODO Figure out how to route this on schema (ws) or HTTP_UGPRADE header... it 
      # all uses HTTP router under the covers, so it should be doable.
      map '/ws/*',  WebSocket
      map '/*',     LongPolling
    end
  end
end