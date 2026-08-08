# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'

class Pagy
  class SyncTask < Rake::TaskLib
    # Define a rake task for syncing a specific resource on demand
    def initialize(resource, destination, *targets)
      namespace :pagy do
        namespace :sync do
          desc "Sync #{resource}"
          task(resource) do
            Pagy.sync(resource, destination, *targets)
          end
        end
      end
    end
  end
end
