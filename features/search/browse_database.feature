@javascript
Feature: Browse database
  As a visitor to the website
  I want to browse the article database
  So that I know whether it contains items of interest

    Background:
      Given I am not logged in

    Scenario: Browse the list of articles
      When I visit the search page
      Then I should see a list of articles

    Scenario: Search for an article
      When I search for articles
      Then I should see a list of articles
        And I should see the number of articles found
