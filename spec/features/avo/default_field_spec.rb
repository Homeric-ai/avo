require "rails_helper"

RSpec.describe "DefaultField", type: :feature do
  describe "with a default value (team - description)" do
    context "create" do
      it "checks presence of default team description" do
        visit "/admin/resources/teams/new"
        wait_for_loaded

        expect(find("#team_description").value).to have_text "This is a wonderful team!"
      end

      it "saves team and checks for default team description value" do
        visit "/admin/resources/teams/new"
        wait_for_loaded

        expect(Team.count).to eql 0

        fill_in "team_name", with: "Joshua Josh"

        save

        expect(current_path).to eql "/admin/resources/teams/#{Team.last.id}"
        expect(find_field_element(:description)).to have_text "This is a wonderful team!"
      end
    end
  end

  describe "with a computable default value (team_membership - level)" do
    let!(:user) { create :user, first_name: "Mihai", last_name: "Marin" }
    let!(:team) { create :team, name: "Apple" }

    context "create" do
      it "checks presence of default team membership level" do
        visit "/admin/resources/memberships/new"
        wait_for_loaded

        if Time.now.hour < 12
          expect(find("#team_membership_level")).to have_text "advanced"
        else
          expect(find("#team_membership_level")).to have_text "beginner"
        end
      end

      it "saves team membership and checks for default team membership level value" do
        visit "/admin/resources/memberships/new"
        wait_for_loaded

        expect(TeamMembership.count).to eql 0

        select "Mihai Marin", from: "team_membership[user_id]"
        select "Apple", from: "team_membership[team_id]"

        save

        expect(current_path).to eql "/admin/resources/memberships/#{TeamMembership.last.id}"

        if Time.now.hour < 12
          expect(find_field_element(:level)).to have_text "advanced"
        else
          expect(find_field_element(:level)).to have_text "beginner"
        end

        expect(find_field_element(:user)).to have_text "Mihai Marin"
        expect(find_field_element(:team)).to have_text "Apple"
      end
    end
  end

  describe "with a computed default value" do
    before :all do
      Avo::Resources::Team.with_temporary_items do
        field :name, as: :text, default: -> do
          result = []
          result << resource.class.to_s
          result << view.to_s
          result << record.class.to_s

          result.join " - "
        end
      end
    end

    after :all do
      Avo::Resources::Team.restore_items_from_backup
    end

    it "fills the field with a computed default value" do
      visit avo.new_resources_team_path

      expect(page).to have_field id: "team_name", with: "Avo::Resources::Team - new - Team"
    end
  end

  it "default do not override value when creation fail" do
    visit avo.new_resources_project_path
    wait_for_loaded

    expect(find("#project_name").value).to have_text "New project default name"

    fill_in "project_name", with: "New name for project"

    save

    expect(page).to have_text "You might have missed something. Please check the form."
    expect(find("#project_name").value).to have_text "New name for project"
  end
end
