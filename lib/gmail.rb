require 'net/imap'
require 'net/smtp'
require 'mail'
require 'date'
require 'time'

if RUBY_VERSION < "1.8.7"
  require "smtp_tls"
end

class Object
  def to_imap_date
    Date.parse(to_s).strftime("%d-%B-%Y")
  end
end

module Gmail
  autoload :Version, "gmail/version"
  autoload :Client,  "gmail/client"
  autoload :Labels,  "gmail/labels"
  autoload :Mailbox, "gmail/mailbox"
  autoload :Message, "gmail/message"

  class << self
    # Creates new Gmail connection using given authorization options.
    #
    # ==== Examples
    #
    #   Gmail.new(:plain, "foo@gmail.com", "password")
    #   Gmail.new(:xoauth, "foo@gmail.com", 
    #     :consumer_key => "",
    #     :consumer_secret => "",
    #     :token => "",
    #     :secret => "")
    #
    # To use plain authentication mehod you can also call:
    #
    #   Gmail.new("foo@gmail.com", "password")
    #
    # You can also use block-style call:
    #
    #   Gmail.new("foo@gmail.com", "password") do |client|
    #     # ...
    #   end
    #

    ['', '!'].each { |kind|
      define_method("new#{kind}") do |*args, &block|
        args.unshift(:plain) unless args.first.is_a?(Symbol)
        client = Gmail::Client.new(*args)
        client.send("connect#{kind}") and client.send("login#{kind}")
        if block_given?
          yield client
          client.logout
        end

        client
      end
    }

    alias :connect :new
    alias :connect! :new!
  end # << self

  # Wrapper class for the Net::IMAP structs that supports
  # the additional Gmail attributes like X-GM-MSGID and X-GM-THRID and
  # generally act more rubyish
  class Address
    attr_accessor :mailbox, :name, :route, :host

    def initialize(args = {})
      @mailbox = args[:mailbox]
      @name = args[:name]
      @route = args[:route]
      @host = args[:host]
    end

    def recipient_address 
      "#{@mailbox}@#{@host}"
    end
  end

  class Envelope
    attr_accessor :sender, :to, :reply_to, :cc, :bcc
    attr_accessor :subject, :date
    attr_accessor :in_reply_to, :message_id
    attr_accessor :gm_msg_id, :gm_thread_id

    def initialize(args={})
      @sender = []
      @to = []
      @cc = []
      @bcc = []

      if args[:src]
        args[:src].sender.to_a.each { |s| @sender.push Address.new(:src => s) }
        args[:src].to.to_a.each { |s| @to.push Address.new(:src => s) }
        args[:src].cc.to_a.each { |s| @cc.push Address.new(:src => s) }
        args[:src].bcc.to_a.each { |s| @bcc.push Address.new(:src => s) }
        @subject = args[:src].subject
        @date = args[:src].date
        @in_reply_to = args[:src].in_reply_to
        @message_id = args[:src].message_id
      end

      @gm_msg_id = args[:gm_msg_id]
      @gm_thread_id = args[:gm_thread_id]
    end

    def url
      return nil unless @gm_msg_id

      "https://mail.google.com/mail/#inbox/#{@gm_msg_id}"
    end
  end
end # Gmail

# Monkey patches to understand the extended Gmail atttributes, and add a
# url method to struct Net::IMAP::Envelope
module Net
  class IMAP
    class ResponseParser
      def msg_att
        match(T_LPAR)
        attr = {}
        while true
          token = lookahead
          case token.symbol
          when T_RPAR
            shift_token
            break
          when T_SPACE
            shift_token
            token = lookahead
          end
          case token.value
          when /\A(?:ENVELOPE)\z/ni
            name, val = envelope_data
          when /\A(?:FLAGS)\z/ni
            name, val = flags_data
          when /\A(?:INTERNALDATE)\z/ni
            name, val = internaldate_data
          when /\A(?:RFC822(?:\.HEADER|\.TEXT)?)\z/ni
            name, val = rfc822_text
          when /\A(?:RFC822\.SIZE)\z/ni
            name, val = rfc822_size
          when /\A(?:BODY(?:STRUCTURE)?)\z/ni
            name, val = body_data
          when /\A(?:UID)\z/ni
            name, val = uid_data
          when /\A(?:X-GM-MSGID)\z/ni
            name, val = uid_data
          when /\A(?:X-GM-THRID)\z/ni
            name, val = uid_data
          else
            parse_error("unknown attribute `%s'", token.value)
          end
          attr[name] = val
        end
        return attr
      end
    end # class ResponseParser
  end # class IMAP
end # module Net
