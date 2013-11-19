require "spec_helper"

describe DeskApiClient do
    before(:each) do
        @client = DeskApiClient.new('test_token', 'test_secret')
    end

    describe "get_topics" do
        #let(:raw_topics) { IO.read(Rails.root.join("spec", "fixtures", "desk", "topics.json")) }

        it "gets all the topics for a desk company" do

            #topics = @client.parse_topics(raw_topics)

            #expect(topics.length).to eq(2)
            #expect(topics.first[:name]).to eq('Customer Support')
        end
    end
end