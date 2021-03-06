module Locomotive
  module Steam
    module Liquid
      module Drops
        class ContentEntry < I18nBase

          delegate :_slug, :_translated, :seo_title, :meta_keywords, :meta_description, to: :@_source

          alias :_permalink :_slug

          def _id
            @_source._id.to_s
          end

          def _label
            @_label ||= @_source._label
          end

          # Returns the next content for the parent content type.
          # If no content is found, nil is returned.
          #
          # Usage:
          #
          # {% if article.next %}
          # <a href="{% path_to article.next %}">Read next article</a>
          # {% endif %}
          #
          def next
            @next ||= repository(@_source).next(@_source).to_liquid
          end

          # Returns the previous content for the parent content type.
          # If no content is found, nil is returned.
          #
          # Usage:
          #
          # {% if article.previous %}
          # <a href="{% path_to article.previous %}">Read previous article</a>
          # {% endif %}
          #
          def previous
            @previous ||= repository(@_source).previous(@_source).to_liquid
          end

          def errors
            @_source.errors.messages.to_hash.stringify_keys
          end

          def before_method(meth)
            return '' if @_source.nil?

            if not @@forbidden_attributes.include?(meth.to_s)
              repository(@_source).value_for(@_source, meth, @context['with_scope'])
            else
              nil
            end
          end

          protected

          def repository(entry)
            repository = @context.registers[:services].repositories.content_entry
            repository.with(entry.content_type)
          end

        end
      end
    end
  end
end
