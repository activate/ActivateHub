require 'source_parser/base'
require 'source_parser/not_found'
require 'source_parser/http_authentication_required_error'

# == SourceParser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
class SourceParser
  # Return an Array of AbstractEvent instances.
  #
  # Options: (these vary between specific parsers)
  # * :url - URL string to read as parser input.
  # * :content - String to read as parser input.
  def self.to_abstract_events(opts)
    matched_parser = self.parsers.find{|parser|
      parser.url_pattern.present? && opts[:url].try(:match, parser.url_pattern)
    }

    # Cache the content
    content = self.content_for(opts)

    # Return events from the first parser that suceeds, starting with the parser
    # that matches the given URL if one is found.
    self.parsers.uniq.unshift(matched_parser).compact.uniq.each do |parser|
      begin
        events = parser.to_abstract_events(opts.merge(:content => content))
        return events if not events.blank?
      rescue ::SourceParser::NotFound => e
        raise e
      rescue ::SourceParser::HttpAuthenticationRequiredError => e
        raise e
      rescue NotImplementedError
        # Ignore
      rescue Exception => e
        # Ignore
        # TODO Eliminate this catch-all rescue and make each parser handle its own exceptions.
      end
    end

    # Return empty set if no matches
    return []
  end

  # Returns an Array of parser classes for the various formats
  def self.parsers
    $SourceParserImplementations.compact
  end

  # Returns an Array of sorted string labels for the parsers.
  def self.labels
    self.parsers.map(&:label).map(&:to_s).sort_by(&:downcase)
  end

  # Return content for the arguments
  def self.content_for(*args)
    ::SourceParser::Base.content_for(*args).to_s.strip
  end

  # Return content for a URL
  def self.read_url(*args)
    ::SourceParser::Base.read_url(*args)
  end
end

# Load format-specific drivers in the following order:
require 'source_parser/plancast'
require 'source_parser/meetup'
require 'source_parser/facebook'
require 'source_parser/ical'
require 'source_parser/hcal'
