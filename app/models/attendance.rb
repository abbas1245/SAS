class Attendance < ApplicationRecord
  # Associations
  belongs_to :student, class_name: 'User'
  belongs_to :teacher, class_name: 'User'

  # Validations
  validates :date, presence: true
  validates :status, presence: true
  validates :student_id, presence: true
  validates :teacher_id, presence: true
  validates :date, uniqueness: { scope: [:student_id, :teacher_id], message: "Attendance already marked for this student on this date" }

  # Enums
  enum :status, { present: 0, absent: 1, late: 2 }, default: :present

  # Scopes
  scope :for_student, ->(student_id) { where(student_id: student_id) }
  scope :for_teacher, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :for_date, ->(date) { where(date: date) }
  scope :recent, -> { order(date: :desc) }

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
    return "<span class='px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800'>Unknown</span>".html_safe if status.nil?
    "<span class='px-2 py-1 text-xs font-semibold rounded-full #{status_color}'>#{status.titleize}</span>".html_safe
  end
end 