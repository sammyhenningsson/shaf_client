require 'spec_helper'

class ShafClient
  describe ProblemJson do
    let(:content_type) { 'application/problem+json' }
    let(:client) { Minitest::Mock.new }
    let(:status) { 403 }
    let(:headers) do
      {
        'content-type' => 'application/problem+json',
        'content-language' => 'en'
      }
    end
	let(:resource) do
	  ShafClient::Resource.build(client, payload, content_type, status, headers)
	end
    let(:payload) do
      {
        type: 'https://example.com/probs/out-of-credit',
        title: 'You do not have enough credit.',
        detail: 'Your current balance is 30, but that costs 50.',
        instance: '/account/12345/msgs/abc',
        balance: 30,
        accounts: [
          '/account/12345',
          '/account/67890'
        ]
      }
    end

    it '#content_type' do
      _(resource.content_type).must_equal 'application/problem+json'
    end

    it '#type' do
      _(resource.type).must_equal 'https://example.com/probs/out-of-credit'
    end

    it '#title' do
      _(resource.title).must_equal 'You do not have enough credit.'
    end

    it '#status' do
      _(resource.status).must_equal 403
    end

    it '#detail' do
      _(resource.detail).must_equal 'Your current balance is 30, but that costs 50.'
    end

    it '#instance' do
      _(resource.instance).must_equal '/account/12345/msgs/abc'
    end

    it 'balance' do
      _(resource.balance).must_equal 30
    end

    it 'accounts' do
      _(resource.accounts).must_equal [
        '/account/12345',
        '/account/67890'
      ]
    end

    describe 'when type is empty' do
      let(:status) { 403 }
      let(:payload) do
        {
          detail: 'Your current balance is 30, but that costs 50.',
          instance: '/account/12345/msgs/abc',
          balance: 30,
          accounts: [
            '/account/12345',
            '/account/67890'
          ]
        }
      end

      it 'sets type to about:blank' do
        _(resource.type).must_equal 'about:blank'
      end

      it '#title' do
        _(resource.title).must_equal 'Forbidden'
      end
    end
  end
end
