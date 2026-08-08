# frozen_string_literal: true

class Pagy
  class Keyset
    # Keyset pagination with broad UI support
    class Keynav < Keyset
      # Avoid conflicts between filter arguments in composite SQL fragments
      PRIOR_PREFIX = 'prior_'
      PAGE_PREFIX  = 'page_'

      # Define empty subclasses to allow specific typing without triggering autoload
      class ActiveRecord < self; end
      class Sequel < self; end

      include NumericHelpers

      # Finalize the instance variables needed for the UI
      def initialize(set, **)
        super

        @previous = @page - 1 unless @page == 1
        @in       = @records.size
      end

      attr_reader :update, :previous, :last
      alias pages last

      # Prepare the @update for the client when it's a new page, and return the next page number
      def next
        records
        @count = 0 if !@more && @page == 1  # empty records (trigger the right info message for known 0 count)
        return unless @more

        @next ||= begin
                    unless @page_cutoff
                      @page_cutoff = extract_cutoff
                      @last       += 1                                # reflect the added cutoff
                      @update.push(@last, [@page, 1, @page_cutoff])   # last + splice arguments for the client cutoffs
                    end
                    @page + 1
                  end
      end

      protected

      def keynav? = true

      # Process the page array
      def assign_page
        if @options[:page]
          storage_key, @page, @last, @prior_cutoff, @page_cutoff = @options[:page]
        else
          @page = @last = 1
        end

        @update = [storage_key, @options[:root_key], @options[:page_key]]
      end

      # Use a compound predicate to fetch the records
      def fetch_records
        return super unless @page_cutoff # last page

        # Compound predicate for visited pages
        predicate = +''
        arguments = {}

        if @prior_cutoff # not the first page
          # Include the records after @prior_cutoff
          predicate << "(#{compose_predicate(PRIOR_PREFIX)}) AND "
          arguments.merge!(arguments_from(@prior_cutoff, PRIOR_PREFIX))
        end

        # Exclude the records after @page_cutoff
        predicate << "NOT (#{compose_predicate(PAGE_PREFIX)})"
        arguments.merge!(arguments_from(@page_cutoff, PAGE_PREFIX))
        apply_where(predicate, arguments)

        @more = true          # not the last page
        @set.limit(nil).to_a  # replaced by the compound predicate
      end

      prepend Deprecated::Keynav if defined?(Deprecated::Keynav)
    end
  end
end
