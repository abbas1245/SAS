class ClassStandard < ApplicationRecord
  # Validations
  validates :name, :code, :year, presence: true
  validates :code, uniqueness: true
  validates :year, numericality: { only_integer: true, greater_than: 0 }
  validates :section, uniqueness: { scope: :year }, allow_nil: true

  # Associations
  has_many :teacher_class_standards
  has_many :teachers, through: :teacher_class_standards, source: :teacher
  has_many :students, -> { where(role: :student) }, class_name: 'User', foreign_key: 'class_standard', primary_key: 'code'

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_year, ->(year) { where(year: year) }
  scope :with_section, ->(section) { where(section: section) }

  # Methods
  def display_name
    section ? "#{name} - #{section}" : name
  end

  def full_code
    "#{year}-#{code}#{section ? "-#{section}" : ''}"
  end

  def primary_teacher
    teacher_class_standards.find_by(is_primary_teacher: true)&.teacher
  end

  def attendance_report
    students.map do |student|
      {
        student: student,
        total_classes: student.attendances.count,
        present_classes: student.attendances.present.count,
        attendance_percentage: student.attendance_percentage,
        short_attendance: student.short_attendance?
      }
    end
  end
end
