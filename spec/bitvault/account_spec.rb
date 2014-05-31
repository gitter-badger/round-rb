require 'spec_helper'

describe BitVault::Account, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:wallet) { authed_client.user.applications[0].wallets[0] }
  let(:passphrase) { 'very insecure' }
  let(:account) { BitVault::Account.new(resource: wallet.accounts[0].resource, wallet: wallet) }

  describe '#initialize' do
    it 'sets the wallet attribute' do
      expect(account.wallet).to eql(wallet)
    end
  end

  describe '#pay' do
    context 'when invalid parameters are passed' do
      it 'raises an error with no payees' do
        expect{ account.pay }.to raise_error(ArgumentError)
      end

      it 'raises an error when anything but an array is passed' do
        expect{ account.pay(payees: Object.new) }.to raise_error(ArgumentError)
      end
    end

    context 'when a transaction is attempted with a locked wallet' do
      it 'raises an error when the wallet is locked' do
        expect{ account.pay(payees: []) }.to raise_error
      end
    end

    context 'when a transaction is attempted with an unlocked wallet' do
      before { 
        wallet.unlock(passphrase) 
        account.resource.payments.stub(:create).and_return({})
        account.stub(:outputs_from_payees).and_return({})
        account.stub(:sign_payment).and_return({})
        BitVault::Bitcoin::Transaction.stub(:data).and_return({})
      }

      it 'returns a Payment model' do
        expect(account.pay(payees: [ {address: 'abcdef123456', amount: 10_000} ]))
          .to be_a_kind_of(BitVault::Payment)
      end
    end
  end

  describe '#outputs_from_payees' do

  end

  describe '#sign_payment'
end