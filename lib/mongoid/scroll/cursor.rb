module Mongoid
  module Scroll
    class Cursor

      attr_accessor :value, :tiebreak_id, :field, :direction

      def initialize(value = nil, options = {})
        unless options && (@field = options[:field])
          raise ArgumentError.new "Missing options[:field]."
        end
        @direction = options[:direction] || '$gt'
        @value, @tiebreak_id = Mongoid::Scroll::Cursor.parse(value, options)
      end

      def criteria
        cursor_criteria = { field.name => { direction => value } } if value
        tiebreak_criteria = { field.name => value, :_id => { '$gt' => tiebreak_id } } if value && tiebreak_id
        (cursor_criteria || tiebreak_criteria) ? { '$or' => [ cursor_criteria, tiebreak_criteria].compact } : {}
      end

      class << self
        def from_record(field, record)
          "#{field.mongoize(record.send(field.name))}:#{record.id}"
        end
      end

      private

        class << self
          def parse(value, options)
            return [ nil, nil ] unless value
            parts = value.split(":")
            unless parts.length >= 2
              raise Mongoid::Scroll::Errors::InvalidCursorError.new({ cursor: value })
            end
            id = parts[-1]
            value = parts[0...-1].join(":")
            [ options[:field].mongoize(value), Moped::BSON::ObjectId(id) ]
          end
        end

    end
  end
end