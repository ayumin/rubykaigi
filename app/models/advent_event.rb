class AdventEvent
  cattr_reader :raw_events
  attr_accessor :id, :name, :dtstart, :dtend, :description, :location, :pub_date

  def initialize(attrs={})
    attrs.symbolize_keys!
    self.id, self.description, self.location = attrs[:id], attrs[:description], attrs[:location]
    self.dtstart  = Time.parse attrs[:dtstart] if attrs[:dtstart].present?
    self.dtend    = Time.parse attrs[:dtend]   if attrs[:dtend].present?
    self.pub_date = Time.parse attrs[:pub_date]   if attrs[:pub_date].present?
    self.name    = attrs["name_#{I18n.locale}".intern]
  end

  def today?
    (dtstart.beginning_of_day..dtend.end_of_day).include? Time.now
  end

  def to_hash
    instance_variables.inject({}) do |hash, ivn|
      hash[ivn[1..-1]] = instance_variable_get ivn
      hash
    end
  end

  class << self
    extend ActiveSupport::Memoizable

    def load(year)
      @@raw_events ||= YAML.load File.open Rails.root.join('db', year.to_s, 'advent_events.yml'), 'r', &:read
    end

    def all
      raw_events.map{|id, e| new e.merge(:id => id) }.sort_by &:dtstart
    end
    memoize :all

    def by_month
      all.inject(ActiveSupport::OrderedHash.new) do |months, event|
        month = event.dtstart.beginning_of_month
        months[month] ||= []
        months[month] << event
        months
      end
    end

  end
end
