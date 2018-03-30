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

      field :expansion, "InterpreterTest::Expansion", null: true do
        argument :sym, String, required: true
      end

      def expansion(sym:)
        EXPANSIONS.find { |e| e.sym == sym }
      end

      CARDS = [
        OpenStruct.new(name: "Dark Confidant", colors: ["BLACK"], expansion_sym: "RAV"),
      ]

      EXPANSIONS = [
        OpenStruct.new(name: "Ravnica, City of Guilds", sym: "RAV"),
      ]
    end

    class Expansion < GraphQL::Schema::Object
      field :sym, String, null: false
      field :cards, ["InterpreterTest::Card"], null: false

      def cards
        Query::CARDS.select { |c| c.expansion_sym == @object.sym }
      end
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
    # TODO encapsulate this in `use` ?
    Schema.graphql_definition.query_execution_strategy = GraphQL::Execution::Interpreter
    # Don't want this wrapping automatically
    Schema.instrumenters[:field].delete(GraphQL::Schema::Member::Instrumentation)
    Schema.instrumenters[:query].delete(GraphQL::Schema::Member::Instrumentation)
  end

  it "runs a query" do
    result = InterpreterTest::Schema.execute <<-GRAPHQL
    {
      card(name: "Dark Confidant") {
        colors
      }
      expansion(sym: "RAV") {
        cards {
          name
        }
      }
    }
    GRAPHQL

    pp result
    assert_equal ["BLACK"], result["data"]["card"]["colors"]
    assert_equal [{"name" => "Dark Confidant"}], result["data"]["expansion"]["cards"]
  end
end
