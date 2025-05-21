class TeacherClassStandard < ApplicationRecord
  # Validations
  validates :start_date, presence: true
  validates :teacher_id, uniqueness: { scope: :class_standard_id, message: "is already assigned to this class" }
  validate :end_date_after_start_date, if: -> { end_date.present? }
  validate :teacher_role_check

  # Associations
  belongs_to :teacher, class_name: 'User'
  belongs_to :class_standard

  # Scopes
  scope :active, -> { where(active: true) }
  scope :current, -> { where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.current, Date.current) }
  scope :primary_teachers, -> { where(is_primary_teacher: true) }

  private

  def end_date_after_start_date
    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def teacher_role_check
    unless teacher&.teacher?
      errors.add(:teacher, "must have teacher role")
    end
  end
end
