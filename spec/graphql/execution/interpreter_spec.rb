# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Interpreter do
  module InterpreterTest
    class Query < GraphQL::Schema::Object
      field :card, "InterpreterTest::Card", null: true do
        argument :name, String, required: true
      end

      def card(name:)
        CARDS.find { |c| c.name == name }
      end

      CARDS = [
        OpenStruct.new(name: "Dark Confidant", colors: ["BLACK"]),
      ]
    end

    class Card < GraphQL::Schema::Object
      field :name, String, null: false
      field :colors, "[InterpreterTest::Color]", null: false
    end

    class Color < GraphQL::Schema::Enum
      value "WHITE"
      value "BLUE"
      value "BLACK"
      value "RED"
      value "GREEN"
    end

    class Schema < GraphQL::Schema
      query(Query)
    end
    Schema.graphql_definition.query_execution_strategy = GraphQL::Execution::Interpreter
  end

  it "runs a query" do
    result = InterpreterTest::Schema.execute <<-GRAPHQL
    {
      card(name: "Dark Confidant") {
        colors
      }
    }
    GRAPHQL

    pp result
    assert_equal ["BLACK"], result["data"]["card"]["colors"]
  end
end
