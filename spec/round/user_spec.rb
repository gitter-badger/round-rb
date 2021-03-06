require 'spec_helper'

describe Round::User do
  let(:applications_resource) { double('applications_resource', list: [])}
  let(:user_resource) { double('user_resource', applications: applications_resource) }
  let(:user) { Round::User.new(resource: user_resource) }

  describe 'delegate methods' do
    it 'delegates update to the resource' do
      expect(user.resource).to receive(:update).with(first_name: 'Julian')
      user.update(first_name: 'Julian')
    end

    [:email, :first_name, :last_name].each do |method|
      it 'delegates email to the resource' do
        expect(user.resource).to receive(method)
        user.send(method)
      end
    end
  end
  
end