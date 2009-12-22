module DataMapper
  module Reflection
    module Builders
      module Source

        def to_ruby
          Model.to_ruby(self)
        end

        class Model

          attr_accessor :model

          def self.to_ruby(model)
            builder = new(model)
            raise DataMapper::IncompleteModelError unless builder.complete_model?
            builder.to_ruby
          end


          def to_ruby
            ruby  = "class #{model}\n"
            ruby += "\n"
            ruby += "  include DataMapper::Resource\n"
            property_definitions(key_properties).each do |key_definition|
              ruby += "\n  #{key_definition}"
            end
            ruby += "\n"
            property_definitions(foreign_key_properties).each do |foreign_key_definition|
              ruby += "\n  #{foreign_key_definition}"
            end
            property_definitions(regular_properties).each do |property_definition|
              ruby += "\n  #{property_definition}"
            end
            ruby += "\n"
            relationship_definitions(many_to_one_relationships).each do |relationship_definition|
              ruby += "\n  #{relationship_definition}"
            end
            relationship_definitions(one_to_one_relationships).each do |relationship_definition|
              ruby += "\n  #{relationship_definition}"
            end
            relationship_definitions(one_to_many_relationships).each do |relationship_definition|
              ruby += "\n  #{relationship_definition}"
            end
            relationship_definitions(many_to_many_relationships).each do |relationship_definition|
              ruby += "\n  #{relationship_definition}"
            end
            ruby += "\n"
            ruby += "\nend\n"
          end



          def key_properties
            model.key
          end

          def foreign_key_properties
            []
          end

          def regular_properties
            model.properties - model.key - foreign_key_properties
          end


          def many_to_one_relationships(repository = :default)
            model.relationships(repository).select do |_, relationship|
              relationship.is_a?(DataMapper::Associations::ManyToOne::Relationship)
            end
          end

          def one_to_one_relationships(repository = :default)
            model.relationships(repository).select do |_, relationship|
              relationship.is_a?(DataMapper::Associations::OneToOne::Relationship)
            end
          end

          def one_to_many_relationships(repository = :default)
            model.relationships(repository).select do |_, relationship|
              relationship.is_a?(DataMapper::Associations::OneToMany::Relationship) &&
              !relationship.is_a?(DataMapper::Associations::ManyToMany::Relationship)
            end
          end

          def many_to_many_relationships(repository = :default)
            model.relationships(repository).select do |_, relationship|
              relationship.is_a?(DataMapper::Associations::ManyToMany::Relationship)
            end
          end


          def complete_model?
            key_properties.any?
          end


          private

          def initialize(model)
            @model = model
          end

          def property_definitions(properties)
            properties.map { |property| Property.for(property).to_ruby }
          end

          def relationship_definitions(relationships)
            relationships.map { |_, relationship| Relationship.for(relationship).to_ruby }
          end

        end


        module OptionBuilder

          def options
            option_string(prioritized_options + rest_options)
          end

          def option_priorities
            []
          end

          def prioritized_options
            []
          end

          def rest_options
            backend_options.select { |k,v| !option_priorities.include?(k) && !irrelevant_options.include?(k) }
          end

          def irrelevant_options
            []
          end

          def backend_options
            @backend_options ||= backend.options.dup
          end


          private

          def option_string(relevant_options)
            return '' if relevant_options.empty?
            ", " + relevant_options.map { |pair| ":#{pair[0]} => #{pair[1]}" }.join(', ')
          end

        end


        class Property

          include OptionBuilder

          attr_accessor :backend

          def self.for(backend)
            new(backend)
          end

          def to_ruby
            "property :#{name}, #{type}#{options}"
          end

          def name
            backend.name
          end

          def type
            Extlib::Inflection.demodulize(backend.type)
          end


          def options
            backend.type == DataMapper::Types::Serial ? '' : super
          end

          def option_priorities
            [ :key, :required, :unique, :unique_index ]
          end

          def prioritized_options
            option_priorities.inject([]) do |memo, name|
              if name == :required
                memo << [ name, backend_options[name] ] if backend_options[name] && !backend_options[:key]
              else
                memo << [ name, backend_options[name] ] if backend_options[name]
              end
              memo
            end
          end

          def irrelevant_options
            []
          end

          private

          def initialize(backend)
            @backend = backend
          end

        end

        class Relationship

          include OptionBuilder

          attr_accessor :backend

          def self.for(backend)
            case backend
            when DataMapper::Associations::ManyToOne::Relationship  then ManyToOne. new(backend)
            when DataMapper::Associations::OneToOne::Relationship   then OneToOne.  new(backend)
            when DataMapper::Associations::OneToMany::Relationship  then OneToMany. new(backend)
            when DataMapper::Associations::ManyToMany::Relationship then ManyToMany.new(backend)
            else
              raise ArgumentError, "#{backend.class} is no valid datamapper relationship"
            end
          end

          def to_ruby
            "#{type} #{cardinality}, :#{name}#{options}"
          end


          def type
            raise NotImplementedError
          end

          def name
            backend.name
          end


          def cardinality
            "#{min}..#{max}"
          end

          def min
            backend.min
          end

          def max
            backend.max
          end


          def option_priorities
            [ :through, :constraint ]
          end

          def prioritized_options
            option_priorities.inject([]) do |memo, name|
              if name == :through && through = backend_options[:through]
                value = through.is_a?(Symbol) ? ":#{through}" : Extlib::Inflection.demodulize(through)
                memo << [ :through, value ]
              end
              memo
            end
          end

          def irrelevant_options
            [ :min, :max, :parent_repository_name, :child_repository_name ]
          end

          private

          def initialize(backend)
            @backend = backend
          end

        end

        class ManyToOne < Relationship
          def to_ruby
            "#{type} :#{name}#{options}"
          end
          def type
            :belongs_to
          end
          def cardinality
            ''
          end
        end

        class OneToOne < Relationship
          def type
            :has
          end
          def cardinality
            min == 1 && max == 1 ? '1' : super
          end
        end

        class OneToMany < Relationship
          def type
            :has
          end
          def cardinality
            max == Infinity ? "#{min}..n" : super
          end
        end

        class ManyToMany < OneToMany
        end

        
      end
    end
  end

  # Ensure activation when this file is required
  Model.append_extensions(Reflection::Builders::Source)

end
