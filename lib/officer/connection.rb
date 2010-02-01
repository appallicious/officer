module Officer
  module Connection

    module EmCallbacks
      def post_init
        L.debug "Client connected."
        @connected = true
      end

      def receive_line line
        line.chomp!
        L.debug "Received line: #{line}"
        tokens = line.split
        command = tokens.shift

        command = Officer::Command::Factory.create command, self, tokens
        command.execute

      rescue Exception => e
        L.debug_exception e
        raise
      end

      def unbind
        @connected = false

        L.debug "client disconnected."
        Officer::LockStore.instance.unbind self
      end
    end

    module LockCallbacks
      def acquired name
        L.debug "acquired lock: #{name}"
        send_line "acquired #{name}"
      end

      def released name
        L.debug "released lock: #{name}"
        send_line "released #{name}"
      end

      def release_failed name
        L.debug "release lock failed: #{name}"
        send_line "release_failed #{name}"
      end
    end

    class Connection < EventMachine::Protocols::LineAndTextProtocol
      include EmCallbacks
      include LockCallbacks

      attr_reader :connected

      def send_line line
        send_data "#{line}\n" if @connected
      end
    end

  end
end