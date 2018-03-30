# frozen_string_literal: true
class GraphQL::STRING_TYPE < GraphQL::Schema::Scalar
  default_scalar true
  description "Represents textual data as UTF-8 character sequences. This type is most often used by GraphQL to represent free-form human-readable text."

  def self.coerce_result(value, ctx)
    str = value.to_s
    str.encoding == Encoding::UTF_8 ? str : str.encode(Encoding::UTF_8)
  rescue EncodingError
    err = GraphQL::StringEncodingError.new(str)
    ctx.schema.type_error(err, ctx)
  end

  def self.coerce_input(value, _ctx)
     value.is_a?(String) ? value : nil
  end
end
