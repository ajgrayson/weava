require "spec_helper"

describe User do
  it "orders by last name" do
    lindeman = User.create!(name: "Andy", email: "andy@me.com")

    expect(User.where("name = ?", 'Andy')).to eq([lindeman])
  end
end