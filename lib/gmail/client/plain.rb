module Gmail
  module Client
    class Plain < Base
      attr_reader :password
      
      def initialize(username, password, options={})
        @password = password
        super(username, options)
      end

      def login()
        @imap and @logged_in = (login = @imap.login(username, password)) && login.name == 'OK'
      rescue Net::IMAP::NoResponseError
        raise AuthorizationError, "Couldn't login to given GMail account: #{username}"
      end
    end # Plain

    register :plain, Plain
  end # Client
end # Gmail
