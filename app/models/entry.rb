class Entry < ActiveRecord::Base
  belongs_to :projects_timesheet
  has_one :project, :through => :projects_timesheet
  has_one :timesheet, :through => :projects_timesheet


  validates_numericality_of :hours

  validates_inclusion_of :presence, :in => :valid_presences, :allow_nil => true
  before_save :set_default_presence, :if => lambda { |e| e.presence.nil? }

  enum :day => {
    :sunday => 0,
    :monday => 1,
    :tuesday => 2,
    :wednesday => 3,
    :thursday => 4,
    :friday => 5,
    :saturday => 6
  }

  enum :presence => {
    :full => 0,
    :half => 1,
    :absent => 2,
    :hourly => 3
  }

  def self.non_zero_entries_for_week_and_project(week, project)
    joins(:timesheet, :projects_timesheet)
      .where(
        "timesheets.year" => week.year,
        "timesheets.month" => week.month,
        "timesheets.day" => week.day,
        "projects_timesheets.project" => project
      ).where.not(:presence => Entry.presences[:absent])
  end

  def valid_presences
    return ["hourly"] if project.hourly?
    self.class.presences.keys - ["hourly"]
  end

  def time
    t = timesheet.time
    until Date::DAYNAMES[t.wday].downcase == day
      t += 1.day
    end
    t
  end

private

  def set_default_presence
    self.presence = if project.hourly?
      :hourly
    elsif sunday? || saturday? || timesheet.projects.first != project
      :absent
    else
      :full
    end
  end

end
