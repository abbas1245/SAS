class Admin::ClassStandardsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_class_standard, only: [:show, :edit, :update, :destroy]

  def index
    @class_standards = ClassStandard.all
  end

  def show
  end

  def new
    @class_standard = ClassStandard.new
  end

  def edit
  end

  def create
    @class_standard = ClassStandard.new(class_standard_params)

    if @class_standard.save
      redirect_to admin_class_standards_path, notice: 'Class standard was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @class_standard.update(class_standard_params)
      redirect_to admin_class_standard_path(@class_standard), notice: 'Class standard was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @class_standard.destroy
    redirect_to admin_class_standards_path, notice: 'Class standard was successfully deleted.'
  end

  private

  def set_class_standard
    @class_standard = ClassStandard.find(params[:id])
  end

  def class_standard_params
    params.require(:class_standard).permit(:name, :description, :code, :year, :section, :active)
  end

  def authorize_admin
    redirect_to root_path, alert: 'Not authorized.' unless current_user.admin?
  end
end 