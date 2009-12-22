require 'spec_helper'
require 'dm-reflection/builders/source_builder'

PERSON = <<-RUBY
class Person

  include DataMapper::Resource

  property :id, Serial

  property :name, String, :required => true, :length => 200
  property :email, String, :required => true, :unique => true, :unique_index => true
  property :created_at, DateTime
  property :updated_at, DateTime

  has 1, :profile
  has 0..n, :projects, :through => Resource

end
RUBY

PROFILE = <<-RUBY
class Profile

  include DataMapper::Resource

  property :id, Serial

  property :person_id, Integer, :required => true, :min => 1
  property :nickname, String
  property :image, String
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :person

end
RUBY

PROJECT = <<-RUBY
class Project

  include DataMapper::Resource

  property :id, Serial

  property :name, String, :required => true, :length => 200
  property :created_at, DateTime
  property :updated_at, DateTime

  has 0..n, :project_tasks
  has 0..n, :tasks, :through => :project_tasks
  has 0..n, :people, :through => Resource

end
RUBY

TASK = <<-RUBY
class Task

  include DataMapper::Resource

  property :id, Serial

  property :name, String, :required => true, :length => 200
  property :email, String, :required => true, :unique => true, :unique_index => true
  property :created_at, DateTime
  property :updated_at, DateTime

  has 0..n, :project_tasks
  has 0..n, :projects, :through => :project_tasks

end
RUBY

PROJECT_TASK = <<-RUBY
class ProjectTask

  include DataMapper::Resource

  property :project_id, Integer, :key => true, :min => 1
  property :task_id, Integer, :key => true, :min => 1

  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :project
  belongs_to :task

end
RUBY

SOURCES = [ PERSON, PROFILE, PROJECT, TASK, PROJECT_TASK ]

describe DataMapper::Reflection::Builders::Source::Model do

  before(:all) do

    SOURCES.each { |source| eval(source) }

    @models = {
      Person      => PERSON,
      Profile     => PROFILE,
      Project     => PROJECT,
      Task        => TASK,
      ProjectTask => PROJECT_TASK
    }

  end

  it "should behave like datamapper when the relation is not in 1NF (raise DataMapper::IncompleteModelError)" do
    invalid_resource = Class.new { include DataMapper::Resource }
    lambda { invalid_resource.to_ruby }.should raise_error(DataMapper::IncompleteModelError)
  end

  it 'should return a proper datamapper model definition' do

    @models.each_pair do |model, source|

      # puts '-'*80
      # puts model.to_ruby
      # puts '-'*80

      model.to_ruby.should == source

    end

  end

end
