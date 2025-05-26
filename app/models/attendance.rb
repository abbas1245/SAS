class Attendance < ApplicationRecord
  # Associations
  belongs_to :student, class_name: 'User'
  belongs_to :teacher, class_name: 'User'

  # Validations
  validates :date, presence: true
  validates :status, presence: true, inclusion: { in: %w[present absent late] }
  validates :student_id, presence: true
  validates :teacher_id, presence: true
  validates :class_standard, presence: true
  validates :date, uniqueness: { scope: [:student_id, :class_standard], message: "Attendance already marked for this student on this date" }

  # Enums
  enum :status, { present: 0, absent: 1, late: 2 }, default: :present, prefix: true

  # Scopes
  scope :for_student, ->(student_id) { where(student_id: student_id) }
  scope :for_teacher, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :for_date, ->(date) { where(date: date) }
  scope :recent, -> { order(date: :desc) }
  scope :for_class, ->(class_standard) { where(class_standard: class_standard) }

  # Methods
  def status_color
    case status
    when 'present'
      'bg-green-100 text-green-800'
    when 'absent'
      'bg-red-100 text-red-800'
    when 'late'
      'bg-yellow-100 text-yellow-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def status_badge
    return "<span class='px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800'>Not Set</span>".html_safe if status.nil?
    "<span class='px-2 py-1 text-xs font-semibold rounded-full #{status_color}'>#{status_display}</span>".html_safe
  end

  def status_display
    return 'Not Set' if status.nil?
    status.to_s.titleize
  end

  def self.mark_attendance(student_id:, teacher_id:, class_standard:, date: Date.current, status:)
    find_or_initialize_by(
      student_id: student_id,
      teacher_id: teacher_id,
      class_standard: class_standard,
      date: date
    ).tap do |attendance|
      attendance.status = status.to_s.downcase.strip
      attendance.save!
    end
  end

  # Callbacks
  before_validation :normalize_status
  after_initialize :set_default_status

  private

  def normalize_status
    self.status = status.to_s.downcase.strip if status.present?
  end

  def set_default_status
    self.status ||= 'present'
  end
end 