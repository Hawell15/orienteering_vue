require "rails_helper"

RSpec.describe User, type: :model do
  describe "admin column" do
    it "defaults to false" do
      user = User.create!(email: "u1@example.com", password: "password")
      expect(user.admin).to be false
    end

    it "can be flipped to true" do
      user = User.create!(email: "u2@example.com", password: "password", admin: true)
      expect(user.admin?).to be true
    end
  end

  describe "devise validations" do
    it "requires a unique email" do
      User.create!(email: "dup@example.com", password: "password")
      user = User.new(email: "dup@example.com", password: "password")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "rejects a short password" do
      user = User.new(email: "u3@example.com", password: "x")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end
  end

  describe ":admin factory trait" do
    it "produces an admin user" do
      expect(FactoryBot.create(:user, :admin).admin?).to be true
    end

    it "produces a non-admin user by default" do
      expect(FactoryBot.create(:user).admin?).to be false
    end
  end
end
