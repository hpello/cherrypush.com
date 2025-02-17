# frozen_string_literal: true

require "application_system_test_case"

class DashboardsTest < ApplicationSystemTestCase
  let!(:user) { create :user }
  let!(:authorized_user) { create :user }
  let!(:organization) { create :organization, name: "cherrypush" }
  let!(:_authorization) { create :authorization, user: authorized_user, organization: organization }
  let!(:project) { create :project, user: user, name: "rails/rails", organization: organization }

  let!(:metric1) { create :metric, project: project, name: "JS LOC" }
  let!(:_report1) { create :report, metric: metric1, value: 12, date: 4.day.ago, value_by_owner: value_by_owner }
  let!(:_report2) { create :report, metric: metric1, value: 9, date: 2.days.ago, value_by_owner: value_by_owner }

  let!(:metric2) { create :metric, project: project, name: "TS LOC" }
  let!(:_report3) { create :report, metric: metric2, value: 12, date: 10.day.ago, value_by_owner: value_by_owner }
  let!(:_report4) { create :report, metric: metric2, value: 9, date: 5.days.ago, value_by_owner: value_by_owner }

  it "allows new users to request access to projects" do
    sign_in(authorized_user, to: user_dashboards_path)

    # Create dashboard
    assert_text "Dashboards"
    assert_text "No dashboards yet"
    click_on "New Dashboard"
    fill_in "Select a project...", with: "rails/rails"
    find("li", text: "rails/rails").click
    fill_in "Dashboard name", with: "TS Migration"
    click_on "Create"
    assert_text "Dashboard created"

    # Create chart
    assert_text "TS Migration"
    assert_text "No charts yet"
    click_on "Add Chart"
    fill_in "Metrics", with: "JS LOC"
    find("li", text: "JS LOC").click
    fill_in "Metrics", with: "TS LOC"
    find("li", text: "TS LOC").click
    mui_select("Line", from: "kind")
    click_on "Create"
    assert_text "New chart added to dashboard"
    assert_equal "line", project.dashboards.sole.charts.sole.kind
    assert_text "JS LOC"
    assert_text "TS LOC"

    # Filter chart
    fill_in("Filter by owners", with: "fwuensche").send_keys(:down).send_keys(:enter)
    fill_in("Filter by owners", with: "rchoq").send_keys(:down).send_keys(:enter)
    assert_text "@fwuensche"
    assert_text "@rchoquet"
    assert current_url.ends_with?("?owners=%40fwuensche%2C%40rchoquet")
    find("span", text: "@fwuensche").click
    assert_no_text "@rchoquet"
    assert current_url.ends_with?("?owners=%40fwuensche")

    # Edit chart
    find("#chart-menu").click
    find("li", text: "Edit").click
    assert_text "Edit Chart"
    sleep 1
    find('[role="button"]', text: "JS LOC").find('[data-testid="CancelIcon"]').click
    within("#chart-drawer-form") { assert_no_text "JS LOC" }
    mui_select("Area", from: "kind")
    assert_equal ["TS LOC", "Area"], all('[role="button"]').map(&:text)
    click_on "Update"
    assert_text "Chart updated"
    assert_equal "area", project.dashboards.sole.charts.sole.kind
    assert_equal "TS LOC", project.dashboards.sole.charts.sole.chart_metrics.sole.metric.name

    # Delete chart
    find("#chart-menu").click
    find("li", text: "Delete").click
    assert_text "Chart deleted"

    # Rename dashboard
    find("#dashboard-menu").click
    find("li", text: "Rename dashboard").click
    fill_in "Name", with: ""
    fill_in "Name", with: "Tech Vitals"
    click_on "Rename"
    assert_text "Dashboard updated"

    # Delete dashboard
    find("#dashboard-menu").click
    find("li", text: "Delete dashboard").click
    assert_text "Dashboard deleted"
    assert_text "No dashboards yet"
  end

  private

  def value_by_owner
    { "@fwuensche" => 10, "@rchoquet" => 8 }
  end
end
