require "http"
require "json"

require_relative "../bitcoin"

module BitVault
  module Blockchain

    # Blockr.io API documentation:  http://blockr.io/documentation/api
    class Blockr
      include BitVault::Encodings

      def initialize(env=:test)
        subdomain = (env.to_sym == :test) ? "tbtc" : "btc"
        @base_url = "http://#{subdomain}.blockr.io/api/v1"
        @http = HTTP.with_headers(
          "User-Agent" => "bv-blockchain-worker v0.1.0",
          "Accept" => "application/json"
        )
      end

      def unspent(addresses, confirmations=6)

        result = request(
          :address, :unspent, addresses,
          :confirmations => confirmations
        )

        outputs = []
        result.each do |record|
          record[:unspent].each do |output|
            address = record[:address]

            transaction_hex, index, value, script_hex =
              output.values_at :tx, :n, :amount, :script

            outputs << BitVault::Bitcoin::Output.new(
              :transaction_hex => transaction_hex,
              :index => index,
              :value => bitcoins_to_satoshis(value),
              :script => {:hex => script_hex},
              :address => address
            )
          end
        end

        outputs.sort_by {|output| -output.value }
      end


      def balance(addresses)
        result = request(:address, :balance, addresses)
        balances = {}
        result.each do |record|
          balances[record[:address]] = float_to_satoshis(record[:balance])
        end

        balances
      end


      def transactions(tx_ids)
        results = request(:tx, :raw, tx_ids)
        results.map do |record|
          hex = record[:tx][:hex]

          transaction = BitVault::Bitcoin::Transaction.hex(hex)
        end
      end


      def address_info(addresses, confirmations=6)
        # Useful for testing transactions()
        request(
          :address, :info, addresses,
          :confirmations => confirmations
        )
      end



      # Helper methods

      def bitcoins_to_satoshis(string)
        string.gsub(".", "").to_i
      end

      def float_to_satoshis(float)
        (float * 100_000_000).to_i
      end


      # Queries the Blockr Bitcoin from_type => to_type API with
      # list, returning the results or throwing an exception on
      # failure.
      def request(from_type, to_type, args, query=nil)
        # Permit calling with either an array or a scalar
        if args.respond_to? :join
          args = args.join(",")
        end
        url = "#{@base_url}/#{from_type}/#{to_type}/#{args}"

        # Construct query string if any params were passed.
        if query
          # TODO: validation.  The value of the "confirmations" parameter
          # must be an integer.
          params = query.map { |name, value| "#{name}=#{value}" }.join("&")
          url = "#{url}?#{params}"
        end

        response = @http.request "GET", url, :response => :object
        # FIXME:  rescue any JSON parsing exception and raise an
        # exception explaining that it's blockr's fault.
        content = JSON.parse(response.body, :symbolize_names => true)

        if content[:status] != "success"
          raise "Blockr.io failure: #{content.to_json}"
        end

        data = content[:data]

        # The endpoints of the API that we use allow multiple arguments
        # and return values, so we always return an array.
        unless data.is_a? Array
          data = [data]
        end

        data
      end

    end

  end
end

