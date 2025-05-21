class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable

  # Add custom password validation to replace devise validatable
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  
  # Enums
  enum :role, { admin: 0, teacher: 1, student: 2 }, default: :admin

  # Scopes
  scope :students, -> { where(role: :student) }
  scope :teachers, -> { where(role: :teacher) }
  scope :admins, -> { where(role: :admin) }
  scope :active, -> { where(active: true) }
  scope :by_class, ->(class_standard) { where(class_standard: class_standard) }

  # Validations
  validates :email, presence: true, uniqueness: true, if: -> { admin? || teacher? }
  validates :email, absence: true, if: :student?
  validates :role, presence: true
  validates :first_name, :last_name, presence: true, if: -> { teacher? || student? }
  validates :class_standard, presence: true, if: :student?
  validates :roll_number, presence: true, if: :student?
  validates :roll_number, format: { with: /\AHS[S][1-9][0-9]{2}\z/, message: "must be in format HSS801" }, if: :student?
  validates :roll_number, uniqueness: true, if: :student?

  # Associations
  # belongs_to :class_standard, optional: true, foreign_key: 'class_standard', primary_key: 'code'
  has_many :teacher_class_standards, foreign_key: :teacher_id, dependent: :destroy
  has_many :assigned_class_standards, through: :teacher_class_standards, source: :class_standard
  has_many :attendances, foreign_key: 'student_id', dependent: :destroy
  has_many :marked_attendances, class_name: 'Attendance', foreign_key: 'teacher_id', dependent: :destroy

  # Callbacks
  after_initialize :set_default_dashboard_settings
  before_validation :set_default_role, on: :create
  before_validation :generate_password_if_teacher, on: :create
  before_validation :clear_email_for_students

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def short_attendance?
    return false unless student?
    attendance_percentage < 75
  end

  def attendance_percentage
    return 0 unless student?
    total = attendances.count
    return 0 if total.zero?
    (attendances.present.count.to_f / total * 100).round(2)
  end

  def role_badge
    case role
    when 'admin'
      '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-purple-100 text-purple-800">Admin</span>'
    when 'teacher'
      '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">Teacher</span>'
    when 'student'
      '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Student</span>'
    else
      '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">No Role</span>'
    end.html_safe
  end

  def dashboard_settings
    super || {}
  end

  def active_for_authentication?
    super && active? && (admin? || teacher?)
  end

  def inactive_message
    if !active?
      :not_approved
    elsif student?
      :student_no_auth
    else
      super
    end
  end

  def teacher?
    role == 'teacher'
  end

  def student?
    role == 'student'
  end

  def admin?
    role == 'admin'
  end

  def self.find_for_authentication(conditions)
    user = find_by(email: conditions[:email])
    return nil unless user

    if user.student?
      nil # Students cannot authenticate
    elsif user.teacher? && !user.encrypted_password.present?
      # If it's a teacher without a password, allow them to set it
      user
    elsif user.encrypted_password.present?
      # For users with passwords, use normal authentication
      user
    else
      nil
    end
  end

  # Add method to determine if password validation is needed
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  private

  def set_default_role
    # Only set default role for new registrations (not for admin-created users)
    self.role ||= :admin if new_record? && !role_changed?
  end

  def generate_password_if_teacher
    if teacher? && !encrypted_password.present?
      # Don't generate a password for teachers - they'll set it during registration
      self.skip_password_validation = true
    end
  end

  def clear_email_for_students
    self.email = nil if student?
  end

  def set_default_dashboard_settings
    return if dashboard_settings.present?
    
    self.dashboard_settings = {
      show_attendance_stats: true,
      show_recent_activities: true,
      show_quick_actions: true,
      default_view: 'overview',
      notification_preferences: {
        email: true,
        dashboard: true
      }
    }
  end
end
