module Round
  class User < Round::Base
    association :wallets, "Round::WalletCollection"
    association :default_wallet, "Round::Wallet"
    association :devices, "Round::DeviceCollection"

    def self.hash_identifier
      "email"
    end
  end

  class UserCollection < Round::Collection

    def content_type
      Round::User
    end

    def create(first_name: nil, last_name: nil, email: nil, passphrase: nil, device_name: nil)
      multiwallet = CoinOp::Bit::MultiWallet.generate([:primary], @client.network)
      primary_seed = CoinOp::Encodings.hex(multiwallet.trees[:primary].seed)
      encrypted_seed = CoinOp::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)
      wallet = {
        name: "default",
        network: @client.network,
        primary_public_seed: multiwallet.trees[:primary].to_serialized_address,
        primary_private_seed: encrypted_seed
      }
      params = {
        email: email,
        first_name: first_name,
        last_name: last_name,
        default_wallet: wallet,
        device_name: device_name
      }
      user_resource = @resource.create(params)
      user = Round::User.new(resource: user_resource, client: @client)
      device_id = user.device_id
      return device_id, user
    end

  end
end
