require 'spec_helper'

describe BitVault::User, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:user) { authed_client.user }

  describe '#initialize' do
    context 'with a valid User resource' do
      it 'should set the resource' do
        expect(user.resource).to_not be_nil
        expect(user.resource).to be_a_kind_of(Patchboard::Resource)
      end
    end
  end

  describe '#update' do
    it 'delegates to the resource' do
      user.resource.should_receive(:update).with({first_name: 'Julian'})
      user.update(first_name: 'Julian')
    end
  end

  describe '#applications' do
    it 'returns an ApplicationCollection' do
      expect(user.applications).to be_a_kind_of(BitVault::ApplicationCollection)
    end
  end 
end