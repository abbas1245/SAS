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
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
  validates :first_name, :last_name, presence: true, if: -> { teacher? || student? }
  validates :class_standard, presence: { message: "must be assigned for students" }, if: :student?
  validates :roll_number, presence: { message: "is required for students" }, if: :student?
  validates :roll_number, format: { with: /\AHS[S][1-9][0-9]{2}\z/, message: "must be in format HSS801" }, if: :student?
  validates :roll_number, uniqueness: true, if: :student?
  validate :class_standard_must_exist, if: :student?

  # Associations
  belongs_to :class_standard, optional: true, foreign_key: 'class_standard', primary_key: 'code', class_name: 'ClassStandard'
  has_many :teacher_class_standards, foreign_key: :teacher_id, dependent: :destroy
  has_many :assigned_class_standards, through: :teacher_class_standards, source: :class_standard
  has_many :attendances, foreign_key: 'student_id', dependent: :destroy
  has_many :marked_attendances, class_name: 'Attendance', foreign_key: 'teacher_id', dependent: :destroy

  # Callbacks
  after_initialize :set_default_dashboard_settings
  before_validation :set_default_role, on: :create
  before_validation :generate_password_if_teacher, on: :create
  before_validation :handle_role_change

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  # Custom setter for class_standard to handle string codes
  def class_standard=(value)
    Rails.logger.info "Setting class_standard to #{value.inspect} (#{value.class})"
    
    if value.is_a?(String)
      # If it's a string, just set it directly
      write_attribute(:class_standard, value)
    elsif value.is_a?(ClassStandard)
      # If it's a ClassStandard object, set the code
      write_attribute(:class_standard, value.code)
    else
      # Default fallback - convert to string
      write_attribute(:class_standard, value.to_s) if value
    end
  end
  
  # Method to access classes taught by the teacher
  def teaching_class_standards
    return ClassStandard.none unless teacher?
    assigned_class_standards.joins(:teacher_class_standards)
                           .where(active: true)
                           .where(teacher_class_standards: {active: true, teacher_id: id})
                           .distinct
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
    super && active?
  end

  def inactive_message
    if !active?
      :not_approved
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

    if user.teacher? && !user.encrypted_password.present?
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

  # Add callbacks to handle role changes
  before_validation :handle_role_change
  
  # Method to handle role changes
  def handle_role_change
    Rails.logger.info "Handling role change from #{role_was} to #{role}"
    
    # If changing from non-student to student
    if will_save_change_to_role? && student? && !role_was.nil? && role_was != 'student'
      # Set default roll number if not present
      self.roll_number ||= generate_default_roll_number
    end
    
    # If changing from student to non-student
    if will_save_change_to_role? && !student? && role_was == 'student'
      # Generate an email if changing from student to another role and email is blank
      self.email ||= generate_default_email
    end

    # Log teacher role changes
    if will_save_change_to_role? && teacher?
      Rails.logger.info "Setting up new teacher: #{inspect}"
    end
  end

  def generate_default_roll_number
    "HSS#{(800 + rand(100)).to_s}"
  end
  
  def generate_default_email
    base_email = "#{first_name.downcase}#{last_name.downcase}"
    "#{base_email.gsub(/[^a-z0-9]/, '')}@example.com"
  end

  # Method to check if the class standard exists
  before_validation :validate_class_standard, if: :student?
  
  def validate_class_standard
    return true unless student?
    return true unless class_standard.present?
    
    # We only care about the class_standard attribute value as a string
    # not as an object or ID reference
    class_code = read_attribute(:class_standard)
    return true if class_code.blank?
    
    # Now check if a class standard with this code exists
    standard = ClassStandard.find_by(code: class_code)
    if standard.nil?
      errors.add(:class_standard, "with code '#{class_code}' does not exist")
      Rails.logger.error "Class standard with code '#{class_code}' does not exist"
      return false
    end
    
    return true
  end

  # Custom validation to check that class_standard exists
  def class_standard_must_exist
    return unless student?
    return unless class_standard.present?
    
    code = read_attribute(:class_standard)
    if code.present? && !ClassStandard.exists?(code: code)
      errors.add(:class_standard, "with code '#{code}' does not exist")
    end
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
