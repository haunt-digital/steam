module Locomotive::Steam
  module Adapters
    module MongoDB

      class Query

        SYMBOL_OPERATORS = %w(all elem_match exists gt gte in lt lte mod ne near near_sphere nin with_size with_type within_box within_circle within_polygon within_spherical_circle)

        attr_reader :criteria, :sort

        def initialize(scope, localized_attributes, &block)
          @criteria, @sort, @fields, @skip, @limit = {}, nil, nil, nil, nil
          @scope, @localized_attributes = scope, localized_attributes

          apply_default_scope

          instance_eval(&block) if block_given?
        end

        def where(criterion = nil)
          self.tap do
            @criteria.merge!(decode_symbol_operators(criterion)) unless criterion.nil?
          end
        end

        def order_by(*args)
          self.tap do
            @sort = [*args]
          end
        end

        def only(*args)
          self.tap do
            @fields = [*args]
          end
        end

        def offset(offset)
          self.tap { @skip = offset }
        end

        def limit(limit)
          self.tap { @limit = limit }
        end

        def against(collection)
          _query = to_origin
          selector, fields, sort = _query.selector, _query.options[:fields], _query.options[:sort]

          collection.find(selector).tap do |results|
            results.sort(sort)      if sort
            results.select(fields)  if fields
            results.skip(@skip)     if @skip
            results.limit(@limit)   if @limit
          end
        end

        def to_origin
          build_origin_query.only(@fields).where(@criteria).order_by(*@sort)
        end

        private

        def build_origin_query
          ::Origin::Query.new(build_aliases(@localized_attributes, @scope.locale))
        end

        def build_aliases(localized_attributes, locale)
          localized_attributes.inject({}) do |aliases, name|
            aliases.tap do
              aliases[name.to_s] = "#{name}.#{locale}"
            end
          end
        end

        def apply_default_scope
          where(site_id: @scope.site._id) if @scope.site
        end

        def decode_symbol_operators(criterion)
          criterion.dup.tap do |_criterion|
            criterion.each do |key, value|
              next unless key.is_a?(String)

              _key, operator = key.split('.')

              if operator && SYMBOL_OPERATORS.include?(operator)
                _criterion.delete(key)
                _key = _key.to_s.to_sym.public_send(operator.to_sym)
                _criterion[_key] = value
              end
            end
          end
        end

      end

    end
  end
end
